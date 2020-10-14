defmodule Mix.Tasks.Fermo.Live do
  use Mix.Task

  @shortdoc "Serves the built site"

  @moduledoc """
  Serves the files from the 'build' directory
  """
  def run(_args) do
    Fermo.Live.App.start(:normal, [])
    Fermo.Live.App.stop(:normal)
  end
end
