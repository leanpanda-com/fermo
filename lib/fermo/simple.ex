defmodule Fermo.Simple do
  @moduledoc """
  Transform non-localized files.

  This module is the simplest case of tranformation:
  it locates all SLIM files not handled by other modules
  and adds them to the transformation queue.
  """
  def add(config) do
    exclude = Map.get(config, :exclude, []) ++ ["partials/*"]
    exclude_matchers = Enum.map(exclude, fn (glob) ->
      single = String.replace(glob, "?", ".")
      multiple = String.replace(single, "*", ".*")
      Regex.compile!(multiple)
    end)

    locales = config[:i18n]
    default_locale = hd(locales)

    templates = File.cd!("priv/source", fn ->
      Path.wildcard("**/*.slim")
    end)

    Enum.reduce(templates, config, fn (template, config) ->
      skip = Enum.any?(exclude_matchers, fn (exclude) ->
        Regex.match?(exclude, template)
      end)
      if skip do
        config
      else
        target = Fermo.template_to_target(template)
        Fermo.add_page(config, template, target, %{}, %{locale: default_locale})
      end
    end)
  end
end
