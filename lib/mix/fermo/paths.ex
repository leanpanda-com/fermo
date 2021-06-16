defmodule Mix.Fermo.Paths do
  @source_path "priv/source"

  def source_path, do: @source_path

  def app_path do
    deps_path = Mix.Project.config[:deps_path]
    Path.dirname(deps_path)
  end

  def full_source_path, do: Path.join(app_path(), source_path())

  def app_relative_path(path) do
    app_path = Path.expand(app_path())
    Path.relative_to(path, app_path)
  end

  def absolute_to_source("/" <> path) do
    absolute_to_source(path)
  end
  def absolute_to_source(path) do
    Path.relative_to(path, @source_path)
  end
end
