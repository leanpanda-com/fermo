defmodule Mix.Tasks.Fermo.Build do
  use Mix.Task

  @shortdoc "Generates the output files"

  @moduledoc """
  Builds the project according to the settings in priv/config.exs
  """
  def run(_args) do
    Mix.Task.run "app.start"
    project = Mix.Project.get()
    [main | _rest] = Module.split(project)
    module = String.to_existing_atom("Elixir.#{main}")
    config = module.config()
    config = Fermo.build(config)
    IO.puts "config: #{inspect(config, [pretty: true, width: 0])}"
    {:ok}
  end
end
