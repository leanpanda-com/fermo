defmodule I18n.Helpers do
  def t(key, parameters \\ %{}, locale)
  def t(key, parameters, locale) when is_atom(locale) do
    I18n.translate!(key, parameters, locale)
  end
  def t(key, parameters, locale) when is_binary(locale) do
    t(key, parameters, String.to_atom(locale))
  end
end
