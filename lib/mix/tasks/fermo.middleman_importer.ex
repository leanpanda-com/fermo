defmodule Mix.Tasks.Fermo.MiddlemanImporter do
  use Mix.Task

  @shortdoc "Converts Ruby-style SLIM files to their Elixir equivalent"

  @moduledoc """
  Takes files in {{source}} and creates Elixir compatible files
  under {{destination}}.
  """

  def run(args) do
    Fermo.MiddlemanImporter.run(args)
  end
end
