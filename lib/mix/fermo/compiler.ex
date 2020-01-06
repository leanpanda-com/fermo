defmodule Mix.Fermo.Compiler do
  import Fermo.Naming
  import Mix.Fermo.Paths
  alias Mix.Fermo.Compiler.Manifest

  def run() do
    compilation_timestamp = compilation_timestamp()
    all_sources = all_sources()
    changed = changed_since(all_sources, Manifest.timestamp())
    Enum.each(changed, &compile_file/1)
    Manifest.write(all_sources, compilation_timestamp)
  end

  defp compile_file(file) do
    module =
      file
      |> absolute_to_source()
      |> source_path_to_module()
    IO.puts "module: #{module}"
  end

  defp changed_since(paths, timestamp) do
    Enum.filter(paths, &(Mix.Utils.last_modified(&1) > timestamp))
  end

  defp all_sources do
    Mix.Utils.extract_files([full_source_path()], [:slim])
    |> MapSet.new()
  end

  def compilation_timestamp, do: System.os_time(:second)
end
