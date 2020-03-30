defmodule Fermo.Routes do
  def root_locale(config) do
    no_root_locale = Map.get(config, :no_root_locale, false)
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

  def default_locale(%{default_locale: default_locale}), do: default_locale
  def default_locale(_), do: nil

  def first_locale(%{i18n: []}), do: nil
  def first_locale(%{i18n: [locale, _rest]}), do: locale
  def first_locale(_config), do: nil
end
