defmodule Fermo.Simple do
  @moduledoc """
  Transform non-localized files.

  This module is the simplest case of tranformation:
  it locates all SLIM files not handled by other modules
  and adds them to the transformation queue.
  """

  import Fermo.Compilers, only: [templates: 1]

  @source_path "priv/source"

  @doc """
  Add a SLIM HTML template to the build
  """
  @callback add(map()) :: map()
  def add(config) do
    exclude = Map.get(config, :exclude, []) ++ ["partials/*"]
    exclude_matchers = Enum.map(exclude, fn (glob) ->
      single = String.replace(glob, "?", ".")
      multiple = String.replace(single, "*", ".*")
      Regex.compile!(multiple)
    end)

    extensions_and_paths =
      templates(@source_path)
      |> Enum.map(fn {extension, path} ->
        {extension, Path.relative_to(path, @source_path)}
      end)

    Enum.reduce(extensions_and_paths, config, fn ({extension, template}, config) ->
      skip = Enum.any?(exclude_matchers, fn (exclude) ->
        Regex.match?(exclude, template)
      end)
      if skip do
        config
      else
        is_html = String.ends_with?(template, ".html.#{extension}")
        target = Fermo.Paths.template_to_target(template, as_index_html: is_html)
        Fermo.Config.add_page(config, template, target, %{})
      end
    end)
  end
end
