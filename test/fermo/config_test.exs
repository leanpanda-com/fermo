defmodule Fermo.ConfigTest do
  use ExUnit.Case, async: true
  import Mox

  alias Fermo.Config

  setup :verify_on_exit!

  setup context do
    build_path = Map.get(context, :build_path, nil)
    pages = Map.get(context, :pages, nil)
    statics = Map.get(context, :statics, nil)

    config = %{
      build_path: build_path,
      pages: pages,
      statics: statics
    }

    stub(Fermo.LocalizableMock, :add, fn config -> config end)
    stub(Fermo.SimpleMock, :add, fn config -> config end)

    Map.merge(context, %{config: config})
  end

  describe "initial/1" do
    test "when not already set, it sets the build_path", context do
      config = Config.initial(context.config)

      assert config.build_path == "build"
    end

    @tag build_path: "foo"
    test "when already set, it doesn't alter the build_path", context do
      config = Config.initial(context.config)

      assert config.build_path == "foo"
    end

    test "when not already set, it initializes the pages list", context do
      config = Config.initial(context.config)

      assert config.pages == []
    end

    @tag pages: ["aaa"]
    test "when already set, it doesn't alter the pages list", context do
      config = Config.initial(context.config)

      assert config.pages == ["aaa"]
    end

    test "when not already set, it initializes the statics list", context do
      config = Config.initial(context.config)

      assert config.statics == []
    end

    @tag statics: ["aaa"]
    test "when already set, it doesn't alter the statics list", context do
      config = Config.initial(context.config)

      assert config.statics == ["aaa"]
    end

    test "it adds localized results", context do
      stub(Fermo.LocalizableMock, :add, fn config -> Map.merge(config, %{foo: :bar}) end)

      config = Config.initial(context.config)

      assert config.foo == :bar
    end

    test "it adds simple results", context do
      stub(Fermo.SimpleMock, :add, fn config -> Map.merge(config, %{foo: :bar}) end)

      config = Config.initial(context.config)

      assert config.foo == :bar
    end

    test "it initializes stats", context do
      config = Config.initial(context.config)

      assert Map.has_key?(config.stats, :start)
    end
  end
end
