defmodule Mix.Tasks.Compile.Fermo do
  use Mix.Task

  @shortdoc "Compile project templates"

  @moduledoc """
  Compile all templates that have changed since the last compile
  """
  def run(_args) do
    Mix.Fermo.Compiler.run()
  end
end
