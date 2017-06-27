defmodule Fermo do
  require EEx
  require Slime

  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo

      @before_compile Fermo
      Module.register_attribute __MODULE__, :config, persist: true
      @config unquote(opts)

      def link_to(text, href, attributes \\ []) do
        attribs = Enum.map(attributes, fn ({k, v}) ->
          "#{k}=\"#{v}\""
        end)
        "<a href=\"#{href}\" #{Enum.join(attribs, " ")}>#{text}</a>"
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    templates = File.cd!("priv/source", fn ->
      Path.wildcard("**/*.slim")
    end)
    defs = Enum.map(templates, fn (path) ->
      Fermo.deftemplate(path)
    end)

    config = Module.get_attribute(env.module, :config)
    exclude = Map.get(config, :exclude, [])
    exclude_matchers = Enum.map(exclude, fn (glob) ->
      single = String.replace(glob, "?", ".")
      multiple = String.replace(single, "*", ".*")
      Regex.compile!(multiple)
    end)

    config = Enum.reduce(templates, config, fn (template, config) ->
      skip = Enum.any?(exclude_matchers, fn (exclude) ->
        Regex.match?(exclude, template)
      end)
      if skip do
        config
      else
        target = String.replace(template, ".slim", "")
        Fermo.add_page(config, template, target)
      end
    end)

    Module.put_attribute(env.module, :config, config)

    get_config = quote do
      def config() do
        hd(__MODULE__.__info__(:attributes)[:config])
      end
    end
    defs ++ [get_config]
  end

  defp full_template_path(path) do
    Path.join(source_path(), path)
  end

  defp source_path, do: "priv/source"
  defp build_path, do: "build"

  def deftemplate(template) do
    [frontmatter, body] = parse_template(template)
    eex_source = Slime.Renderer.precompile(body)
    name = String.to_atom(template)
    quote bind_quoted: binding() do
      info = [file: __ENV__.file, line: __ENV__.line]
      compiled = EEx.compile_string(eex_source, info)
      escaped_frontmatter = Macro.escape(frontmatter)
      args = [Macro.var(:params, nil)]

      # Define a method with the frontmatter, so we can merge with
      # params when the template is evaluated
      def unquote(:"#{name}-defaults")() do
        unquote(escaped_frontmatter)
      end

      def unquote(name)(unquote_splicing(args)) do
        unquote(compiled)
      end
    end
  end

  defmacro proxy(config, template, target, params \\ %{}) do
    quote bind_quoted: binding() do
      Fermo.add_page(config, template, target, params)
    end
  end

  def add_page(config, template, target, params \\ %{}) do
    pages = Map.get(config, :pages, [])
    page = %{
      template: template,
      target: target,
      params: params
    }
    put_in(config, [:pages], pages ++ [page])
  end

  defmacro build(config \\ %{}) do
    quote bind_quoted: binding() do
      Fermo.do_build(__MODULE__, config)
    end
  end

  def do_build(module, config) do
    pages = config[:pages]
    pages_with_body = Enum.map(pages, fn (%{template: template, params: params} = page) ->
      body = build_page(module, template, params)
      put_in(page, [:body], body)
    end)
    config = put_in(config, [:pages], pages_with_body)

    File.mkdir(build_path())

    pages = config[:pages]
    Enum.each(pages, fn (%{body: body, target: target}) ->
      pathname = Path.join(build_path(), target)
      path = Path.dirname(pathname)
      File.mkdir(path)
      File.write!(pathname, body, [:write])
    end)
    config
  end

  def build_page(module, template, params \\ %{}) do
    defaults_method = String.to_atom(template <> "-defaults")
    defaults = apply(module, defaults_method, [])
    args = Map.merge(defaults, params)
    name = String.to_atom(template)
    content = apply(module, name, [args])
    apply(module, :"layouts/layout.html.slim", [%{content: content}])
  end

  def parse_template(path) do
    File.read(full_template_path(path)) |> split_template
  end

  def split_template({:ok, source = "---\n" <> _rest}) do
    [_, frontmatter_yaml, body] = String.split(source, "---\n")
    frontmatter = YamlElixir.read_from_string(frontmatter_yaml)
    [Macro.escape(frontmatter, unquote: true), body]
  end
  def split_template({:ok, body}) do
    [Macro.escape(%{}, unquote: true), body]
  end
end
