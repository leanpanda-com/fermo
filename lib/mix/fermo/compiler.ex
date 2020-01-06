defmodule Mix.Fermo.Compiler do
  import Mix.Fermo.Paths

  @manifest_vsn 1

  def run() do
    compilation_timestamp = compilation_timestamp()
    all_sources = all_sources()
    changed = changed_since(all_sources, manifest_timestamp())
    IO.puts "changed: #{inspect(changed, [pretty: true, width: 0])}"
    write_manifest(all_sources, compilation_timestamp)
  end

  defp changed_since(paths, timestamp) do
    Enum.filter(paths, &(Mix.Utils.last_modified(&1) > timestamp))
  end

  defp all_sources do
    Mix.Utils.extract_files([full_source_path], [:slim])
    |> MapSet.new()
  end

  defp manifest do
    if File.exists?(manifest_path()) do
      case File.read!(manifest_path()) |> :erlang.binary_to_term() do
        [@manifest_vsn | sources] -> sources
        _ -> MapSet.new({})
      end
    else
      MapSet.new([])
    end
  end

  defp write_manifest(sources, timestamp) do
    manifest_data =
      [@manifest_vsn | sources]
      |> :erlang.term_to_binary([:compressed])
    File.write!(manifest_path(), manifest_data)
    File.touch!(manifest_path(), timestamp)
  end

  def compilation_timestamp, do: System.os_time(:second)
  def manifest_timestamp, do: Mix.Utils.last_modified(manifest_path())

  defp manifest_path do
    Path.join(Mix.Project.manifest_path(), "compile.fermo")
  end
end
