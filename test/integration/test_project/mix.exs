defmodule TestProject.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :test_project,
      version: "0.1.0",
      elixir: "~> 1.9",
      compilers: Mix.compilers() ++ [:fermo],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:fermo, ">= 0.0.0", path: "../../.."},
      {:fermo_helpers, "~> 0.12.0"}
    ]
  end
end
