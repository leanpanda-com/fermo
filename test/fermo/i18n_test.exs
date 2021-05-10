defmodule Fermo.I18nTest do
  use ExUnit.Case, async: true

  describe "optionally_build_path_map/1" do
    setup context do
      i18n = Map.get(context, :i18n, ~w(en it tr)a)
      path_map = Map.get(context, :path_map, true)

      config = %{
        i18n: i18n,
        path_map: path_map,
        pages: [
          %{path: "/foo", options: %{locale: :en, id: 1}},
          %{path: "/it/foo", options: %{locale: :it, id: 1}}
        ],
        stats: %{}
      }

      Map.put(context, :config, config)
    end

    test "it builds a path map", context do
      config = Fermo.I18n.optionally_build_path_map(context.config)

      page = hd(config.pages)
      assert get_in(page, [:localized_paths, :it]) == "/it/foo"
    end

    @tag i18n: nil
    test "when no locales are set, it does not build a path map", context do
      config = Fermo.I18n.optionally_build_path_map(context.config)

      page = hd(config.pages)
      assert get_in(page, [:localized_paths, :it]) == nil
    end

    @tag path_map: false
    test "when path_map is not set, it does not build a path map", context do
      config = Fermo.I18n.optionally_build_path_map(context.config)

      page = hd(config.pages)
      assert get_in(page, [:localized_paths, :it]) == nil
    end

    @tag pages: [
      %{path: "/foo", options: %{locale: "en", id: 1}},
      %{path: "/it/foo", options: %{locale: :it, id: 1}}
    ]
    test "when locales are strings, it handles them", context do
      config = Fermo.I18n.optionally_build_path_map(context.config)

      page = hd(config.pages)
      assert get_in(page, [:localized_paths, :it]) == "/it/foo"
    end
  end
end
