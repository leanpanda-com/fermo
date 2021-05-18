defmodule Mix.Tasks.Fermo.New do
  @moduledoc "Generate a Fermo project"

  use Mix.Task

  @version Mix.Project.config()[:version]

  @fermo_new Application.get_env(:fermo_new, :fermo_new, Fermo.New)

  @shortdoc "Creates a new Fermo v#{@version} project"
  @impl true
  def run(argv) do
    @fermo_new.run(argv)
  end
end
