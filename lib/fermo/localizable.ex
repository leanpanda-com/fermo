defmodule Fermo.Localizable do
  def add(config) do
    locales = config[:i18n]
    default_locale = hd(locales)

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
          localized_target = if locale == default_locale do
              target
            else
              "#{locale}/#{target}"
            end
          Fermo.add_page(config, template, localized_target, %{}, %{locale: locale})
        end)
      else
        config
      end
    end)
  end
end
