defmodule Fermo.New.Project do
  @moduledoc false

  defstruct [:app, :module, :path]

  @type t :: %__MODULE__{
    app: binary(),
    module: binary(),
    path: Path.t()
  }

  @callback build(String.t()) :: {:ok, __MODULE__} | {:error, atom(), String.t()}
  @doc ~S"""
  Builds a Project structure

    iex> Fermo.New.Project.build("foo")
    {:ok, %Fermo.New.Project{app: :foo, module: "Foo", path: "foo"}}

  Requires a name consisting of alphanumerics and underscores

    iex> Fermo.New.Project.build("/path/foo")
    {
      :error,
      :bad_name,
      "The app name '/path/foo' is incorrect. The name must start with a lower-case letter and contain only alphanumeric characters and underscores"
    }
  """
  def build(path) do
    with {:ok} <- check_name(path),
         {:ok, project} <- do_build(path) do
      {:ok, project}
    else
      {:error, error, message} ->
        {:error, error, message}
    end
  end

  def do_build(path) do
    {
      :ok,
      %__MODULE__{
        app: String.to_atom(path),
        module: Macro.camelize(path),
        path: path
      }
    }
  end

  defp check_name(name) do
    if name =~ Regex.recompile!(~r/^[a-z][\w_]*$/) do
      {:ok}
    else
      {:error, :bad_name, "The app name '#{name}' is incorrect. The name must start with a lower-case letter and contain only alphanumeric characters and underscores"}
    end
  end
end
