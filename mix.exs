defmodule Fermo.MixProject do
  use Mix.Project

  @version "0.13.5"
  @git_origin "https://github.com/leanpanda-com/fermo"

  def project do
    [
      app: :fermo,
      version: @version,
      elixir: "~> 1.9",
      name: "Fermo",
      description: "A static site generator",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      docs: [
        extras: ["README.md", "MiddlemanToFermo.md"],
        homepage_url: @git_origin,
        main: "Fermo",
        source_ref: "v#{@version}",
        source_url: @git_origin
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Fermo, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:fermo_helpers, "~> 0.12.0"},
      {:file_system, ">= 0.0.0"},
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
