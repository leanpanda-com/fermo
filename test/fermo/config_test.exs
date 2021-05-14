defmodule Fermo.ConfigTest do
  use ExUnit.Case, async: true
  import Mox

  alias Fermo.Config

  setup :verify_on_exit!

  describe "add_page/4" do
    setup do
      config = %{pages: []}

      %{config: config}
    end

    test "it adds a page", context do
      config = Config.add_page(context.config, "template", "target", "params")

      page = hd(config.pages)
      assert page == %{template: "template", target: "target", params: "params"}
    end
  end

  describe "add_static/3" do
    test "it adds a static page" do
      config = Config.add_static(%{statics: []}, "source", "target")

      assert hd(config.statics) == %{source: "source", target: "target"}
    end
  end

  describe "page_from/3" do
    test "it returns the page" do
      assert Config.page_from("a", "b", "c") == %{template: "a", target: "b", params: "c"}
    end
  end

  describe "initial/1" do
    setup context do
      build_path = Map.get(context, :build_path, nil)
      pages = Map.get(context, :pages, nil)
      statics = Map.get(context, :statics, nil)
      stats = Map.get(context, :stats, nil)

      config = %{
        build_path: build_path,
        pages: pages,
        stats: stats,
        statics: statics
      }

      stub(Fermo.LocalizableMock, :add, fn config -> config end)
      stub(Fermo.SimpleMock, :add, fn config -> config end)

      Map.merge(context, %{config: config})
    end

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

  describe "post_config/1" do
    setup context do
      defaults = Map.get(context, :defaults, %{})
      # This depends on the default content_for returning "" and not nil
      pages = Map.get(context, :pages, [%{template: "mock_template", target: "target", params: %{foo: :bar}}])
      content_for_path = Map.get(context, :content_for_path, "")

      stub(Fermo.TemplateMock, :module_for_template, fn _ -> "module" end)
      stub(Fermo.TemplateMock, :build_context, fn _, _, _ -> %{} end)
      stub(Fermo.TemplateMock, :params_for, fn _, _ -> %{} end)
      stub(Fermo.TemplateMock, :content_for, fn _, [:path, _, _] -> content_for_path end)
      stub(Fermo.TemplateMock, :defaults_for, fn _ -> defaults end)
      stub(Fermo.I18nMock, :optionally_build_path_map, fn config -> config end)

      config = %{
        build_path: "foo",
        pages: pages,
        stats: [],
        statics: []
      }

      config = if Map.has_key?(context, :config_layout) do
        Map.put(config, :layout, context.config_layout)
      else
        config
      end

      Map.merge(context, %{config: config})
    end

    test "it sets the page path", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.path == "target"
    end

    test "it sets the page target", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.target == "target"
    end

    @tag content_for_path: "ciao"
    test "when the template overrides the path, it sets that path", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.path == "ciao"
    end

    @tag content_for_path: "ciao"
    test "when the template overrides the path, it uses that path for the target", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.target == "ciao/index.html"
    end

    @tag defaults: %{baz: :qux}
    test "it merges page params with frontmatter defaults", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.baz == :qux
    end

    test "it sets a default layout", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.layout == "layouts/layout.html.slim"
    end

    @tag defaults: %{layout: "layouts/from_frontmatter"}
    test "frontmatter layouts override the default layout", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.layout == "layouts/from_frontmatter.html.slim"
    end

    @tag defaults: %{layout: "custom"}
    test "it uses any layout set in frontmatter", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.layout == "custom.html.slim"
    end

    @tag config_layout: "foo"
    test "it uses any layout set in config", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.layout == "foo.html.slim"
    end

    @tag config_layout: "from_config"
    @tag defaults: %{layout: "from_frontmatter"}
    test "the frontmatter layout takes precedence over the config layout", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.layout == "from_frontmatter.html.slim"
    end

    @tag config_layout: "from_config"
    @tag defaults: %{layout: "from_frontmatter"}
    @tag pages: [%{template: "mock_template", target: "target", params: %{layout: "from_page"}}]
    test "the page layout takes precedence over the frontmatter and config layouts", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.layout == "from_page.html.slim"
    end

    test "it sets the module", context do
      config = Config.post_config(context.config)

      page = hd(config.pages)

      assert page.params.module == "module"
    end

    test "it builds localized paths", context do
      expect(Fermo.I18nMock, :optionally_build_path_map, fn config -> config end)

      Config.post_config(context.config)
    end
  end
end
