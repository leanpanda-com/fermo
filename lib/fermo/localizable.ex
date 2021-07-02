defmodule Fermo.Localizable do
  import Fermo.Compilers, only: [templates: 1]
  import Fermo.I18n, only: [root_locale: 1]

  @source_path "priv/source"

  @callback add(map()) :: map()
  def add(%{i18n: i18n} = config) do
    root_locale = root_locale(config)
    locales = i18n

    exclude = Map.get(config, :exclude, []) ++ ["localizable/*"]
    config = put_in(config, [:exclude], exclude)

    extensions_and_paths =
      templates(Path.join(@source_path, "localizable"))
      |> Enum.map(fn {extension, path} ->
        {extension, Path.relative_to(path, @source_path)}
      end)

    Enum.reduce(extensions_and_paths, config, fn ({extension, template}, config) ->
      target = String.replace_prefix(template, "localizable/", "")
      is_html = String.ends_with?(template, ".html.#{extension}")
      target = Fermo.Paths.template_to_target(target, as_index_html: is_html)
      Enum.reduce(locales, config, fn (locale, config) ->
        localized_target = if locale == root_locale do
            "/#{target}"
          else
            "/#{locale}/#{target}"
          end
        Fermo.Config.add_page(config, template, localized_target, %{locale: locale})
      end)
    end)
  end
  def add(config), do: config
end
