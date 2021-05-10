defmodule Mix.GeneratorBehaviour do
  @callback create_directory(Path.t()) :: true
  @callback create_file(Path.t(), String.t()) :: boolean()
end
