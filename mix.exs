defmodule Fermo.MixProject do
  use Mix.Project

  def project do
    [
      app: :fermo,
      version: "0.1.0",
      elixir: "~> 1.9",
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
      {:slime, "~> 0.16.0"},
      {:yaml_elixir, "~> 1.3.0"}
    ]
  end
end
