defmodule Fermo.MixProject do
  use Mix.Project

  # N.B.: Keep aligned with the versions in installer/mix.exs
  @version "0.14.3"
  @elixir_version "~> 1.9"
  @git_origin "https://github.com/leanpanda-com/fermo"

  def project do
    [
      app: :fermo,
      version: @version,
      elixir: @elixir_version,
      name: "Fermo",
      description: "A static site generator",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      docs: [
        main: "readme",
        extras: [
          "README.md",
          "ARCHITECTURE.md",
          "CHANGELOG.md",
          "MiddlemanToFermo.md"
        ],
        homepage_url: @git_origin,
        source_ref: "v#{@version}",
        source_url: @git_origin
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: extra_applications(Mix.env()),
      mod: {Fermo, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp extra_applications(:test), do: [:logger, :mox]
  defp extra_applications(_env), do: [:logger]

  defp deps do
    [
      {:deep_merge, ">= 1.0.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:excoveralls, ">= 0.0.0", only: :test},
      {:file_system, ">= 0.0.0"},
      {:jason, ">= 1.0.0"},
      {:morphix, ">= 0.0.0"},
      {:mox, ">= 0.0.0", only: :test, runtime: false},
      {:plug_cowboy, "~> 2.0"},
      {:slime, "~> 1.2.1"},
      {:yaml_elixir, "~> 1.3.0"}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/leanpanda-com/fermo"
      },
      maintainers: ["Joe Yates"]
    }
  end
end
