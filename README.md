# Entrace Live Dashboard

Puts function tracing right into your Phoenix Live Dashboard.

## Early version

The UI is still kind of rough. Should be plenty useful though. Contributions are very welcome.

## Installation

Add it to your deps in `mix.exs`:

```elixir
# ..
{:entrace_live_dashboard, "~> 0.1"}
# ..
```

Then add the page to your live_dashboard route in `router.ex`:

```elixir
  live_dashboard "/dashboard",
    metrics: SampleWeb.Telemetry,
    additional_pages: [
      trace_calls:
        {EntraceLiveDashboard.PhoenixLiveDashboard.TraceCallPage, tracer: Sample.Tracer}
    ]
```

Visit your dashboard path and visit the "Trace Calls" menu item.