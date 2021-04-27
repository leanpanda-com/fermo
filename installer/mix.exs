defmodule Fermo.New.MixProject do
  use Mix.Project

  @fermo_mix_exs File.read!("../mix.exs")
  @version hd(Regex.run(~r<@version\s+\"([^\"]+)\">, @fermo_mix_exs, capture: :all_but_first))
  @elixir_version hd(Regex.run(~r<elixir:\s+\"([^\"]+)\">, @fermo_mix_exs, capture: :all_but_first))
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
      {:ex_doc, "~> 0.24", only: :docs}
    ]
  end

  defp docs do
    []
  end
end
