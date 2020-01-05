defmodule Fermo.Helpers.I18n do
  @doc false
  defmacro __using__(_opts) do
    quote do
      require Fermo.Helpers.I18n

      def t(key, parameters \\ %{}, locale) do
        I18n.translate!(key, parameters, locale)
      end
    end
  end

  def load!(config) do
    files = Path.wildcard("priv/locales/**/*.yml")
    translations = Enum.reduce(files, %{}, fn (file, translations) ->
      content = YamlElixir.read_from_file(file)
      {:ok, atom_keys} = Morphix.atomorphiform(content)
      DeepMerge.deep_merge(translations, atom_keys)
    end)
    {:ok} = I18n.put(translations)
  end
end
