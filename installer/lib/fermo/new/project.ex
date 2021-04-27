defmodule Fermo.New.Project do
  @moduledoc false

  defstruct [:app, :module, :path]

  @type t :: %__MODULE__{
    app: binary(),
    module: binary(),
    path: Path.t()
  }
end
