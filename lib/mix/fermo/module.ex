defmodule Mix.Fermo.Module do
  @moduledoc """
  Conveniences for Fermo Mix tasks
  """
  def module! do
    project = Mix.Project.get()
    [main | _rest] = Module.split(project)
    String.to_existing_atom("Elixir.#{main}")
  end
end
