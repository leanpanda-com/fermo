defmodule <%= @project[:module] %>.MixProject do
  use Mix.Project

  def project do
    [
      app: :<%= @project[:app] %>,
      version: "0.1.0",
      elixir: "<%= @config[:elixir] %>",
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
      {:fermo, "<%= @config[:version] %>"}<%= @mix[:other_deps] %>
    ]
  end
end
