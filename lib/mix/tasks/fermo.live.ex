defmodule Mix.Tasks.Fermo.Live do
  use Mix.Task

  @shortdoc "Serves the built site and watches for changes"

  @moduledoc """
  Serves the files from the 'build' directory,
  watches for changes to templates and recompiles them.
  """
  def run(_args) do
    Mix.Task.run "app.start"
    {:ok, _pid} = Fermo.Live.App.start(:normal, [])
    port = Fermo.Live.App.port()
    IO.puts "Fermo Live is running on port #{port}"
    t = Task.async(fn -> IO.gets("") end)
    Task.await(t, :infinity)
    Fermo.Live.App.stop(:normal)
  end
end
