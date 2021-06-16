defmodule Fermo.New.MixProject do
  use Mix.Project

  # N.B.: Keep aligned with the versions in ../mix.exs
  @version "0.14.9"
  @elixir_version "~> 1.9"
  @scm_url "https://github.com/leanpanda.com/fermo"

  def project do
    [
      app: :fermo_new,
      start_permanent: Mix.env() == :prod,
      version: @version,
      elixir: @elixir_version,
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps(),
      package: [
        maintainers: ["Joe Yates"],
        licenses: ["MIT"],
        links: %{"GitHub" => @scm_url},
        files: ~w(lib templates mix.exs README.md)
      ],
      preferred_cli_env: [docs: :docs],
      source_url: @scm_url,
      docs: docs(),
      homepage_url: "https://www.getfermo.com",
      description: """
      Fermo project generator.

      Provides a `mix fermo.new` task to bootstrap a new Fermo project
      with the standard dependencies for use with DatoCMS.
      """
    ]
  end

  def application do
    [
      extra_applications: extra_applications(Mix.env()),
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp extra_applications(:test), do: [:eex, :mox]
  defp extra_applications(_env), do: [:eex]

  def deps do
    [
      {:ex_doc, "~> 0.24", only: :dev},
      {:mox, ">= 0.0.0", only: :test, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      homepage_url: @scm_url,
      source_ref: "v#{@version}",
      source_url: @scm_url
    ]
  end
end
