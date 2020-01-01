defmodule I18n do
  use GenServer

  def init(args) do
    {:ok, args}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: :i18n)
  end

  def put(translation_tree) do
    {:ok, collapsed} = collapse(translation_tree)
    {:ok} = GenServer.call(:i18n, {:put, {collapsed}})
  end

  def translate(key, locale) when is_list(key) do
    translate(to_string(key), locale)
  end
  def translate(key, locale) do
    GenServer.call(:i18n, {:translate, key, locale})
  end

  def translate!(key, locale) do
    {:ok, translation} = translate(key, locale)
    translation
  end

  def t(key, locale) do
    translate!(key, locale)
  end

  def handle_call({:put, state}, _from, _state) do
    {:reply, {:ok}, state}
  end
  def handle_call({:translate, key, locale}, _from, {translations} = state) do
    {:reply, {:ok, translations[locale][key]}, state}
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
end
