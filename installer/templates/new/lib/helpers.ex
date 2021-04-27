defmodule Helpers do
  defmacro __using__(_opts \\ %{}) do
    quote do
      import DatoCMS.GraphQLClient
      import DatoCMS.GraphQLClient.MetaTagHelpers
      import FermoHelpers.Links

      def environment, do: System.get_env("BUILD_ENV")
    end
  end
end
