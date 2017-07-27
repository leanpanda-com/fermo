defmodule Fermo.Helpers.I18n do
  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo.Helpers.I18n

      def current_locale do
        I18n.get_locale!()
      end

      def t(key) do
        I18n.translate!(key)
      end
    end
  end
end
