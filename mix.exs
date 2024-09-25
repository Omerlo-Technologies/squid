defmodule Squid.MixProject do
  use Mix.Project

  def project do
    [
      app: :squid,
      version: "0.1.5",
      build_path: "./_build",
      config_path: "./config/config.exs",
      deps_path: "./deps",
      lockfile: "./mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.19"},
      {:phoenix_html, "~> 3.1 or ~> 4.0"},
      {:jason, "~> 1.3", optional: true},
      {:ex_doc, "~> 0.29.4", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp description do
    "Squid is a framework that helps you divide your application into multiple " <>
      "small contexts and/or applications called `tentacles`."
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Omerlo-Technologies/squid"},
      source_url: "https://github.com/Omerlo-Technologies/squid"
    ]
  end
end
