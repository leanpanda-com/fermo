defmodule MixBehaviour do
  @callback raise(binary()) :: no_return()
  @callback shell() :: module()
end
