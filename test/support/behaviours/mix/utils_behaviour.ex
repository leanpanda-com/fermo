defmodule Mix.UtilsBehaviour do
  @callback last_modified(Path.t()) :: integer()
  @callback extract_files([Path.t()], [atom()]) :: [Path.t()]
end
