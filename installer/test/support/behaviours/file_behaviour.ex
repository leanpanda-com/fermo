defmodule FileBehaviour do
  @callback dir?(Path.t()) :: boolean()
  @callback ls(Path.t()) :: [Path.t()] | {:error, :noent}
  @callback ls!(Path.t()) :: [Path.t()]
  @callback mkdir_p!(Path.t()) :: :ok
  @callback read!(Path.t()) :: String.t()
  @callback regular?(Path.t()) :: boolean()
  @callback rename!(Path.t(), Path.t()) :: :ok
  @callback rm_rf!(Path.t()) :: :ok
  @callback write!(Path.t(), String.t()) :: :ok
end
