defmodule EntraceLiveDashboard.PhoenixLiveDashboard.TraceCallPage do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  @impl Phoenix.LiveDashboard.PageBuilder
  def init(opts) do
    tracer = Keyword.fetch!(opts, :tracer)

    {:ok, %{tracer: tracer}, []}
  end

  @impl Phoenix.LiveDashboard.PageBuilder
  def menu_link(_, _) do
    {:ok, "Trace Calls"}
  end

  @impl Phoenix.LiveDashboard.PageBuilder
  def mount(_params, session, socket) do
    modules =
      Entrace.Utils.list_modules()
      |> Entrace.Utils.trim_elixir_namespace()

    socket =
      socket
      |> assign(
        pattern_form: blank_input_form(),
        tracer: session.tracer,
        set_pattern_result: nil,
        traces: nil,
        modules: modules,
        functions: []
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveDashboard.PageBuilder
  def handle_event("selection", %{"module" => module}, socket) do
    # This stuff is messy and silly but works at least :)
    module =
      try do
        full = "Elixir." <> module

        full
        |> String.to_existing_atom()
        |> Code.ensure_loaded()

        full
      rescue
        _ ->
          try do
            module
            |> String.to_existing_atom()
            |> Code.ensure_loaded()
          rescue
            _ ->
              nil
          end

          module
      end

    try do
      functions = Entrace.Utils.list_functions_for_module(module) |> Enum.map(&elem(&1, 0))
      {:noreply, assign(socket, functions: functions)}
    rescue
      _ ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveDashboard.PageBuilder
  def handle_event(
        "start-trace",
        %{"module" => module, "function" => function, "arity" => arity},
        socket
      ) do
    arity =
      case arity do
        "_" -> :_
        num -> String.to_integer(num)
      end

    module =
      try do
        String.to_existing_atom("Elixir." <> module)
      rescue
        _ ->
          String.to_existing_atom(module)
      end

    mfa = {module, String.to_existing_atom(function), arity}
    result = socket.assigns.tracer.trace_cluster(mfa, self())

    socket =
      socket
      |> assign(
        set_pattern_result: result,
        traces: []
      )

    {:noreply, socket}
  end

  @impl Phoenix.LiveDashboard.PageBuilder
  def handle_info({:trace, trace}, socket) do
    traces = [trace | socket.assigns.traces]
    socket = assign(socket, traces: traces)
    Process.put(:traces, {traces, Enum.count(traces)})
    {:noreply, socket}
  end

  @impl Phoenix.LiveDashboard.PageBuilder
  def render(assigns) do
    ~H"""
    <section id="trace-call-form">
      <.form for={@pattern_form} phx-submit="start-trace" phx-change="selection">
        <label>
          Module
          <input
            type="text"
            class="form-control form-control-sm"
            name="module"
            list="modules"
            placeholder="GenServer"
            value=""
          />
          <datalist id="modules">
            <%= for mod <- @modules do %>
              <option value={mod |> to_string() |> String.replace("Elixir.", "")} />
            <% end %>
          </datalist>
        </label>

        <label>
          Function
          <input
            type="text"
            class="form-control form-control-sm"
            name="function"
            list="functions"
            value="_"
          />
          <datalist id="functions">
            <%= for fun <- @functions do %>
              <option value={fun} />
            <% end %>
          </datalist>
        </label>
        <label>
          Arity <input type="text" class="form-control form-control-sm" name="arity" value="_" />
        </label>
        <button class="btn btn-primary btn-sm">Start trace</button>
      </.form>
    </section>
    <section :if={@set_pattern_result} id="trace-set-pattern-result">
      <%= show_result(@set_pattern_result) %>
    </section>
    <section :if={@traces} id="trace-call-results">
      <.live_table
        id="traces-table"
        dom_id="traces-table"
        page={@page}
        title="Trace calls"
        row_fetcher={&fetch_traces/2}
        row_attrs={&row_attrs/1}
      >
        <:col :let={trace} field={:id}>
          <%= trace.id %>
        </:col>
        <:col :let={%{mfa: {m, _, _}} = trace} field={:module}>
          <%= m %>
        </:col>
        <:col :let={%{mfa: {_, f, _}} = trace} field={:function}>
          <%= f %>
        </:col>
        <:col :let={%{mfa: {_, _, a}} = trace} field={:arity}>
          <%= Enum.count(a) %>
        </:col>
        <:col :let={%{mfa: {_, _, a}} = trace} field={:arguments}>
          <%= inspect(a) %>
        </:col>
        <:col :let={trace} field={:pid}>
          <%= inspect(trace.pid) %>
        </:col>
        <:col :let={trace} field={:called_at} sortable={:desc}>
          <%= trace.called_at %>
        </:col>
        <:col :let={trace} field={:returned_at} sortable={:desc}>
          <%= if trace.returned_at do
            trace.returned_at
          end %>
        </:col>
        <:col :let={trace} field={:took_ms} sortable={:desc}>
          <%= if trace.returned_at do
            DateTime.diff(trace.returned_at, trace.called_at, :microsecond)
          end %>
        </:col>
        <:col :let={trace} field={:return_value}>
          <%= if trace.return_value do
            inspect(trace.return_value)
          end %>
        </:col>
      </.live_table>
    </section>
    """
  end

  def trace(assigns) do
    ~H"""
    <div><%= @trace.id %></div>
    """
  end

  defp blank_input_form do
    to_form(%{"module" => "_", "function" => "_", "arity" => "_"}, as: :pattern)
  end

  def fetch_traces(params, node) do
    %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

    Process.get(:traces) || {[], 0}
  end

  def row_attrs(table) do
    [
      # {"phx-click", "show_info"},
      # {"phx-value-info", encode_ets(table[:id])},
      {"phx-page-loading", true}
    ]
  end

  defp show_result(result) do
    case result do
      [{:ok, {:set, functions_matched}} | _] ->
        "Functions matched #{functions_matched}."

      [{:ok, {:reset_existing, functions_matched}} | _] ->
        "Reset existing trace. Functions matched #{functions_matched}."

      [{:error, :full_wildcard_rejected} | _] ->
        "Matching a full wildcard is not allowed."

      [{:error, {:covered_already, mfa}} | _] ->
        "The chosen pattern is covered by an existing trace (#{inspect(mfa)})."
    end
  end
end
