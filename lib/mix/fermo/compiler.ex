defmodule Mix.Fermo.Compiler do
  import Mix.Fermo.Paths
  alias Mix.Fermo.Compiler.Manifest

  def run() do
    compilation_timestamp = compilation_timestamp()
    all_sources = all_sources()
    changed = changed_since(all_sources, Manifest.timestamp())
    IO.puts "changed: #{inspect(changed, [pretty: true, width: 0])}"
    Manifest.write(all_sources, compilation_timestamp)
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
