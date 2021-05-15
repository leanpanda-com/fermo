defmodule Helpers do
  @moduledoc false

  defmacro __using__(_opts \\ %{}) do
    quote do
      import FermoHelpers.Links

      def environment, do: System.get_env("BUILD_ENV")
    end
  end
end
