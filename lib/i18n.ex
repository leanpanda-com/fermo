defmodule I18n do
  use GenServer

  def init(args) do
    {:ok, args}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: :i18n)
  end

  def put(translation_tree, locale) do
    {:ok, collapsed} = collapse(translation_tree)
    {:ok} = GenServer.call(:i18n, {:put, {collapsed, locale}})
  end

  def set_locale(locale) when is_atom(locale) do
    {:ok} = GenServer.call(:i18n, {:set_locale, locale})
  end
  def set_locale(locale) do
    set_locale(String.to_atom(locale))
  end

  def get_locale do
    GenServer.call(:i18n, {:get_locale})
  end

  def get_locale! do
    {:ok, locale} = get_locale()
    locale
  end

  def translate(key) when is_list(key) do
    translate(to_string(key))
  end
  def translate(key) do
    GenServer.call(:i18n, {:translate, key})
  end
  def translate!(key) do
    {:ok, translation} = translate(key)
    translation
  end

  def t(key) do
    translate!(key)
  end

  def handle_call({:put, state}, _from, _state) do
    {:reply, {:ok}, state}
  end
  def handle_call({:set_locale, locale}, _from, {translations, _locale}) do
    {:reply, {:ok}, {translations, locale}}
  end
  def handle_call({:get_locale}, _from, {_translations, locale} = state) do
    {:reply, {:ok, locale}, state}
  end
  def handle_call({:translate, key}, _from, {translations, locale} = state) do
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
