defmodule I18n do
  use GenServer

  def init(args) do
    {:ok, args}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: :i18n)
  end

  def put(translation_tree) do
    {:ok, collapsed} = collapse(translation_tree)
    {:ok} = GenServer.call(:i18n, {:put, {collapsed}})
  end

  def translate(key, parameters \\ %{}, locale)
  def translate(key, parameters, locale) when is_list(key) and is_atom(locale) do
    translate(to_string(key), parameters, locale)
  end
  def translate(key, parameters, locale) when is_atom(locale) do
    GenServer.call(:i18n, {:translate, key, parameters, locale})
  end

  def translate!(key, parameters \\ %{}, locale) do
    {:ok, translation} = translate(key, parameters, locale)
    translation
  end

  def handle_call({:put, state}, _from, _state) do
    {:reply, {:ok}, state}
  end
  def handle_call({:translate, key, parameters, locale}, _from, {translations} = state) do
    translated = translations[locale][key]
    translation = substitute(translated, parameters)
    {:reply, {:ok, translation}, state}
  end

  # We want to turn the nested structure into a simple Map
  # with keys like "a.b.c"
  defp collapse(translation_tree) do
    collapsed = Enum.reduce(translation_tree, %{}, fn ({locale, tree}, acc) ->
      nested = do_collapse(tree, [])
      twoples = List.flatten(nested)
      flat_map = Enum.into(twoples, %{})
      put_in(acc, [locale], flat_map)
    end)
    {:ok, collapsed}
  end

  defp do_collapse(tree, parents) when is_map(tree) do
    Enum.map(tree, fn ({k, v}) -> do_collapse({k, v}, parents) end)
  end
  defp do_collapse({key, map}, parents) when is_map(map) do
    do_collapse(map, parents ++ [key])
  end
  defp do_collapse({key, value}, parents) do
    keys = Enum.join(parents ++ [key], ".")
    {keys, value}
  end

  defp substitute(translation, parameters) when parameters == %{} do
    translation
  end
  defp substitute(translation, parameters) do
    Regex.replace(
      ~r/%\{([^}]+)\}/,
      translation,
      fn _match, key -> parameters[String.to_atom(key)] || "" end
    )
  end
end
