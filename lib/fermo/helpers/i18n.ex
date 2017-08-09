defmodule Fermo.Helpers.I18n do
  @doc false
  defmacro __using__(_opts) do
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

  def load!(config) do
    default_locale = hd(config[:i18n])
    files = Path.wildcard("priv/locales/**/*.yml")
    translations = Enum.reduce(files, %{}, fn (file, translations) ->
      content = YamlElixir.read_from_file(file)
      {:ok, atom_keys} = Morphix.atomorphiform(content)
      Map.merge(translations, atom_keys)
    end)
    {:ok} = I18n.put(translations, default_locale)
  end
end
