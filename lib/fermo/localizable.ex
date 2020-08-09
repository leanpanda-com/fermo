defmodule Fermo.Localizable do
  import Fermo.Routes, only: [root_locale: 1]

  def add(%{i18n: _i18n} = config) do
    root_locale = root_locale(config)
    locales = config.i18n

    exclude = Map.get(config, :exclude, []) ++ ["localizable/*"]
    config = put_in(config, [:exclude], exclude)

    templates = File.cd!("priv/source", fn ->
      Path.wildcard("**/*.slim")
    end)

    Enum.reduce(templates, config, fn (template, config) ->
      if String.starts_with?(template, "localizable/") do
        target = String.replace_prefix(template, "localizable/", "")
        target = Fermo.template_to_target(target, as_index_html: true)
        Enum.reduce(locales, config, fn (locale, config) ->
          localized_target = if locale == root_locale do
              "/#{target}"
            else
              "/#{locale}/#{target}"
            end
          Fermo.add_page(config, template, localized_target, %{}, %{locale: locale})
        end)
      else
        config
      end
    end)
  end
  def add(config), do: config
end
