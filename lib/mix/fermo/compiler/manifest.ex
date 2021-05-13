defmodule Mix.Fermo.Compiler.Manifest do
  @manifest_vsn 1

  @callback timestamp() :: term()
  def timestamp, do: Mix.Utils.last_modified(path())

  def path do
    Path.join(Mix.Project.manifest_path(), "compile.fermo")
  end

  def read do
    if File.exists?(path()) do
      case File.read!(path()) |> :erlang.binary_to_term() do
        [@manifest_vsn | sources] -> sources
        _ -> MapSet.new({})
      end
    else
      MapSet.new([])
    end
  end

  @callback write([Path.t()], term()) :: {:ok}
  def write(sources, timestamp) do
    manifest_data =
      [@manifest_vsn | sources]
      |> :erlang.term_to_binary([:compressed])
    path = path()
    File.write!(path, manifest_data)
    File.touch!(path, timestamp)
    {:ok}
  end
end
