defmodule Fermo.New.MixProject do
  use Mix.Project

  # N.B.: Keep aligned with the versions in ../mix.exs
  @version "0.13.9"
  @elixir_version "~> 1.9"
  @scm_url "https://github.com/leanpanda.com/fermo"

  def project do
    [
      app: :fermo_new,
      start_permanent: Mix.env() == :prod,
      version: @version,
      elixir: @elixir_version,
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
      extra_applications: [:eex]
    ]
  end

  def deps do
    [
      {:ex_doc, "~> 0.24", only: :dev}
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
