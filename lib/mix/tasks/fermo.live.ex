defmodule Mix.Tasks.Fermo.Live do
  use Mix.Task

  @shortdoc "Serves the built site"

  @moduledoc """
  Serves the files from the 'build' directory
  """
  def run(_args) do
    {:ok, _pid} = Fermo.Live.App.start(:normal, [])
    IO.puts "Fermo Live is running on port 4001"
    t = Task.async(fn -> IO.gets("") end)
    Task.await(t, :infinity)
    Fermo.Live.App.stop(:normal)
  end
end
