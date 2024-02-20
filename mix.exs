defmodule EntraceLiveDashboard.MixProject do
  use Mix.Project

  def project do
    [
      app: :entrace_live_dashboard,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Docs
      name: "Entrace Live Dashboard",
      description: "Putting the best the BEAM has to offer, right in your Phoenix Live Dashboard",
      source_url: "https://github.com/underjord/entrace_live_dashboard",
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ],
      package: [
        name: :entrace_live_dashboard,
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/underjord/entrace_live_dashboard"}
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.7"},
      {:phoenix_live_view, "~> 0.19.0"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:jason, "~> 1.2"},
      {:entrace, "~> 0.1"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    []
  end
end
