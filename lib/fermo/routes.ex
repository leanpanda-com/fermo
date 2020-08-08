defmodule Fermo.I18n do
  defstruct [
    :no_root_locale,
    :default_locale,
    locales: []
  ]

  def root_locale(%{i18n: i18n}) do
    no_root_locale = Map.get(i18n, :no_root_locale, false)
    if no_root_locale do
      nil
    else
      default_locale = default_locale(config)
      if default_locale do
        default_locale
      else
        first_locale(config)
      end
    end
  end
  def root_locale(_config) do
    nil
  end

  def locales(%{i18n: %{locales: locales}}), do locales
  def locales(_config), do []

  def default_locale(%{i18n: %{default_locale: default_locale}}) do
    default_locale
  end
  def default_locale(_), do: nil

  def first_locale(config) do
    with [first|_rest] <- locales(config) do
      first
    else
      nil
    end
  end
end
