defmodule Fermo.MixProject do
  use Mix.Project

  def project do
    [
      app: :fermo,
      version: "0.1.5",
      elixir: "~> 1.4",
      description: "A static site generator",
      package: package(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_doc, "~> 0.15.1", only: :dev},
      {:exjsx, "~> 3.2"},
      {:morphix, "~> 0.0.7"},
      {:slime, "~> 1.0.0"},
      {:yaml_elixir, "~> 1.3.0"}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/joeyates/fermo.git"
      },
      maintainers: ["Joe Yates"]
    }
  end
end
