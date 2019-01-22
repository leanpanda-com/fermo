defmodule Mix.Tasks.Fermo.Build do
  use Mix.Task

  @shortdoc "Generates the output files"

  @moduledoc """
  Builds the project according to the settings in __MODULE__.build()
  """
  def run(_args) do
    Mix.Task.run "app.start"
    project = Mix.Project.get()
    [main | _rest] = Module.split(project)
    module = String.to_existing_atom("Elixir.#{main}")
    config = module.build()
    stats = config.stats
    log("Data load", stats, :start, :data_loaded)
    log("Page preparation", stats, :prepare_pages, :pages_prepared)
    log("Build", stats, :pages_prepared, :pages_built)
    {:ok}
  end

  defp log(message, stats, from, to) do
    if (stats[to] != nil) and (stats[from]) != nil do
      diff = Time.diff(stats[to], stats[from], :microsecond)
      IO.puts "#{message}: #{diff / 1000000}s"
    end
  end
end
