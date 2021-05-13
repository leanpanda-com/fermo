defmodule FileBehaviour do
  @callback stream!(Path.t(), [atom()]) :: File.Stream.t()
  @callback write!(Path.t(), String.t()) :: :ok
  @callback write!(Path.t(), String.t(), [atom()]) :: :ok
end
