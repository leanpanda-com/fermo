defmodule Fermo.File do
  def copy(source, destination) do
    path = Path.dirname(destination)
    File.mkdir_p(path)
    {:ok, _files} = File.cp_r(source, destination)
  end

  def save(pathname, body) do
    path = Path.dirname(pathname)
    File.mkdir_p(path)
    File.write!(pathname, body, [:write])
  end
end
