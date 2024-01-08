defmodule EntraceLiveDashboard.Router do
  @moduledoc """
  Provides LiveView routing for EntraceLiveDashboard.
  """

  @doc """
  Defines an EntraceLiveDashboard route.

  It expects the `path` the tracing tool will be mounted at
  and a set of options.

  ## Examples

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import EntraceLiveDashboard.Router

        scope "/", MyAppWeb do
          pipe_through [:browser]
          entrace_live_dashboard "/tracing"
        end
      end

  """
  defmacro entrace_live_dashboard(path, opts \\ []) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    scope =
      quote bind_quoted: binding() do
        scope path, alias: false, as: false do
          {session_name, session_opts, route_opts} = EntraceLiveDashboard.Router.__options__(opts)

          import Phoenix.Router, only: [get: 4]
          import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

          live_session session_name, session_opts do
            # Assets
            # get "/css-:md5", EntraceLiveDashboard.Assets, :css, as: :entrace_live_dashboard_asset
            # get "/js-:md5", EntraceLiveDashboard.Assets, :js, as: :entrace_live_dashboard_asset

            # All helpers are public contracts and cannot be changed
            live "/", EntraceLiveDashboard.PageLive, :home, route_opts
            live "/:page", EntraceLiveDashboard.PageLive, :page, route_opts
          end
        end
      end

    quote do
      unquote(scope)

      unless Module.get_attribute(__MODULE__, :entrace_live_dashboard_prefix) do
        @entrace_live_dashboard_prefix Phoenix.Router.scoped_path(__MODULE__, path)
        def __entrace_live_dashboard_prefix__, do: @entrace_live_dashboard_prefix
      end
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:entrace_live_dashboard, 2}})

  defp expand_alias(other, _env), do: other

  @doc false
  def __options__(options) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    session_args = []

    {
      options[:live_session_name] || :entrace,
      [
        session: {__MODULE__, :__session__, session_args},
        root_layout: {EntraceLiveDashboard.LayoutView, :dash},
        on_mount: options[:on_mount] || nil
      ],
      [
        private: %{live_socket_path: live_socket_path},
        as: :entrace_live_dashboard
      ]
    }
  end

  @doc false
  def __session__(conn) do
    %{}
  end
end
