defmodule Mix.Tasks.Fermo.Live do
  use Mix.Task

  @shortdoc "Serves the built site"

  @moduledoc """
  Serves the files from the 'build' directory
  """
  def run(_args) do
    {:ok, _pid} = Fermo.Live.App.start(:normal, [])
  end
end
