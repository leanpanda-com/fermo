defmodule Fermo.MixProject do
  use Mix.Project

  @version "0.7.0"
  @git_origin "https://github.com/leanpanda-com/fermo"

  def project do
    [
      app: :fermo,
      version: @version,
      elixir: "~> 1.9",
      description: "A static site generator",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "Fermo",
        extras: ["README.md", "MiddlemanToFermo.md"],
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
      {:deep_merge, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:fermo_helpers, "~> 0.6.0"},
      {:jason, "~> 1.1"},
      {:morphix, "~> 0.0.7"},
      {:slime, "1.0.0"},
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
