defmodule Fermo.I18n do
  def load(path \\ "priv/locales/**/*.yml") do
    files = Path.wildcard(path)
    translations = Enum.reduce(files, %{}, fn (file, translations) ->
      content = YamlElixir.read_from_file(file)
      {:ok, atom_keys} = Morphix.atomorphiform(content)
      DeepMerge.deep_merge(translations, atom_keys)
    end)
    {:ok} = I18n.put(translations)
  end

  @doc """
  Cross references all config pages, finding those with the same `:id`
  but with different locales.

  Each page with an `:id` and `:locale` in its parameters has
  a `:localized_paths` Map added indicating which locale has
  which path.

  E.g.

     %{
       path: "/",
       template: "home.html.slim",
       localized_paths: %{
         en: "/",
         it: "/it/"
       },
       params: %{
         id: "home_page",
         locale: :en
       }
     }

  In templates, this data is available via `context.page.localized_paths`.
  """
  @callback optionally_build_path_map(map()) :: map()
  def optionally_build_path_map(%{i18n: nil} = config), do: config
  def optionally_build_path_map(%{path_map: true, i18n: _i18n} = config) do
    pages_with_locale_and_id = Enum.filter(
      config.pages,
      fn %{params: params} ->
        Map.has_key?(params, :locale) && Map.has_key?(params, :id)
      end
    )

    path_locale_id = Enum.map(
      pages_with_locale_and_id,
      fn page ->
        %{path: page.path, id: page.params.id, locale: atom(page.params.locale)}
      end
    )

    by_id = Enum.group_by(path_locale_id, &(&1.id))

    path_map = Enum.into(
      by_id,
      %{},
      fn {id, pages} ->
        {
          id,
          Enum.into(pages, %{}, fn item -> {item.locale, item.path} end)
        }
      end
    )

    pages = Enum.map(
      config.pages,
      fn %{params: params} = page ->
        if Map.has_key?(params, :locale) && Map.has_key?(params, :id) do
          map = path_map[params.id]
          put_in(page, [:localized_paths], map)
        else
          page
        end
      end
    )

    config
    |> put_in([:pages], pages)
    |> put_in([:stats, :optionally_build_path_map_completed], Time.utc_now)
  end
  def optionally_build_path_map(config), do: config

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
  def first_locale(%{i18n: [locale | _rest]}), do: locale
  def first_locale(_config), do: nil

  defp atom(x) when is_atom(x), do: x
  defp atom(x), do: String.to_atom(x)
end
