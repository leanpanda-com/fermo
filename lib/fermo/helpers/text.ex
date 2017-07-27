defmodule Fermo.Helpers.Text do
  @doc false
  defmacro __using__(_opts \\ %{}) do
    quote do
      require Fermo.Helpers.Text

      def truncate_words(text, options \\ []) do
        length = options[:length] || 30
        omission = options[:omission] || "..."
        words = String.split(text)
        if length(words) <= length do
          text
        else
          incipit = Enum.slice(words, 0..length)
          Enum.join(incipit, " ") <> omission
        end
      end
    end
  end
end


