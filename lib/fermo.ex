defmodule Fermo do
  require EEx
  require Slime

  def start(_start_type, _args \\ []) do
    I18n.start_link()
    Fermo.Assets.start_link()
  end

  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo

      @before_compile Fermo
      Module.register_attribute __MODULE__, :config, persist: true
      @config unquote(opts)

      use Fermo.Helpers.Assets
      use Fermo.Helpers.Links
      use Fermo.Helpers.I18n
      use Fermo.Helpers.Text

      defmacro partial(name, params \\ nil) do
        template = "partials/_#{name}.html.slim"
        quote do
          page = var!(context)[:page]
          Fermo.render_template(__MODULE__, unquote(template), page, unquote(params))
        end
      end

      def environment, do: "production" # TODO

      defmacro yield_content(name) do
        name_atom = if is_atom(name), do: name, else: String.to_atom(name)
        quote do
          context = var!(context)
          page = context[:page]
          params = page.params
          template = page.template
          template_atom = if is_atom(template), do: template, else: String.to_atom(template)
          apply(__MODULE__, :content_for, [template_atom, unquote(name_atom), params, context])
        end
      end
    end
  end

  def template_to_target(template, opts \\ [])
  def template_to_target(template, as_index_html: true) do
    target = String.replace(template, ".slim", "")
    if target == "index.html" || String.ends_with?(target, "/index.html") do
      target
    else
      String.replace(target, ".html", "/index.html")
    end
  end
  def template_to_target(template, _opts) do
    String.replace(template, ".slim", "")
  end

  @doc false
  defmacro __before_compile__(env) do
    config = Module.get_attribute(env.module, :config)

    config = Fermo.Localizable.add(config)
    config = Fermo.Simple.add(config)

    templates = File.cd!("priv/source", fn ->
      Path.wildcard("**/*.slim")
    end)
    defs = Enum.map(templates, fn (path) ->
      Fermo.deftemplate(path)
    end)

    Module.put_attribute(env.module, :config, config)

    get_config = quote do
      def config() do
        hd(__MODULE__.__info__(:attributes)[:config])
      end
    end
    defs ++ [get_config]
  end

  defp source_path, do: "priv/source"
  defp build_path, do: "build"

  def deftemplate(template) do
    [frontmatter, body, content_fors] = parse_template(template)
    name = String.to_atom(template)
    eex_source = Slime.Renderer.precompile(body)
    defs = quote bind_quoted: binding() do
      compiled =
        try do
          info = [file: template, line: 1]
          EEx.compile_string(eex_source, info)
        rescue
          e ->
            IO.puts "Failed to precompile template: '#{template}'"
            IO.puts "\nbody:\n#{body}\n"
            raise e
        catch
          e ->
            IO.puts "Failed to precompile template: '#{template}'"
            IO.puts "\nbody:\n#{body}\n"
            raise e
        end
      escaped_frontmatter = Macro.escape(frontmatter)
      args = [Macro.var(:params, nil), Macro.var(:context, nil)]

      # Define a method with the frontmatter, so we can merge with
      # params when the template is evaluated
      def unquote(:"#{name}-defaults")() do
        unquote(escaped_frontmatter)
      end

      def unquote(name)(unquote_splicing(args)) do
        _params = var!(params)
        _context = var!(context)
        unquote(compiled)
      end
    end
    [defs] ++ content_fors
  end

  def proxy(config, template, target, params \\ nil, options \\ nil) do
    Fermo.add_page(config, template, target, params, options)
  end

  def paginate(config, template, items, params \\ %{}, options \\ %{}) do
    Fermo.Pagination.paginate(config, template, items, params, options)
  end

  def page_from(template, target, params \\ %{}, options \\ %{}) do
    %{
      template: template,
      target: target,
      params: params,
      options: options
    }
  end

  def add_page(config, template, target, params \\ %{}, options \\ %{}) do
    pages = Map.get(config, :pages, [])
    page = page_from(template, target, params, options)
    put_in(config, [:pages], pages ++ [page])
  end

  defmacro build(config \\ %{}) do
    quote bind_quoted: binding() do
      Fermo.do_build(__MODULE__, config)
    end
  end

  def do_build(module, config) do
    Fermo.Helpers.I18n.load!(config)

    pages = config[:pages]
    pages_with_body = Enum.map(pages, fn (page) ->
      body = render_page(module, page)
      put_in(page, [:body], body)
    end)
    config = put_in(config, [:pages], pages_with_body)

    File.mkdir(build_path())

    pages = config[:pages]
    Enum.each(pages, fn (%{body: body, target: target}) ->
      pathname = Path.join(build_path(), target)
      path = Path.dirname(pathname)
      File.mkdir_p(path)
      File.write!(pathname, body, [:write])
    end)
    config
  end

  def render_template(module, template, page, params \\ %{}) do
    context = %{
      module: module,
      template: template,
      page: page
    }
    name = String.to_atom(template)
    apply(module, name, [params, context])
  end

  def render_body(module, %{template: template, params: params} = page, defaults) do
    args = Map.merge(defaults, params)
    render_template(module, template, page, args)
  end

  def build_layout_with_content(module, content, page, layout) do
    layout_template = "layouts/" <> layout
    layout_params = %{content: content}
    render_template(module, layout_template, page, layout_params)
  end

  def render_page(module, %{template: template} = page) do
    %{options: options} = page
    {:ok, previous_locale} = I18n.get_locale()
    locale = options[:locale]
    if locale do
      I18n.set_locale(locale)
    end
    defaults_method = String.to_atom(template <> "-defaults")
    defaults = apply(module, defaults_method, [])
    layout = if Map.has_key?(defaults, "layout") do
      defaults["layout"]
    else
      "layout.html.slim" # TODO: make this a setting
    end
    content = render_body(module, page, defaults)
    result = if layout do
      build_layout_with_content(module, content, page, layout)
    else
      content
    end
    I18n.set_locale(previous_locale)
    result
  end

  def extract_content_for_block(template, part) do
    # Extract the content_for block (until the next line that isn't indented)
    # TODO: the block should not stop at the first non-indented **empty** line,
    #   it should continue to the first non-indented line with text
    [key | [block | cleaned]] = Regex.run(~r/^(?:[\(\s]\:)([^\n\)]+)\)?\n((?:\s{2}[^\n]+\n)+)(.*)/s, part, capture: :all_but_first)
    # Strip leading blank lines
    block = String.replace(block, ~r/^[\s\r\n]*/, "", global: false)
    # Strip indentation
    block = String.replace(block, ~r/^  /m, "")
    cf_def = quote bind_quoted: [block: block, template: template, key: key] do
      eex_source = Slime.Renderer.precompile(block)
      compiled =
        try do
          info = [file: template, line: 1]
          EEx.compile_string(eex_source, info)
        rescue
          e ->
            IO.puts "Failed to precompile content_for block in '#{template}'"
            IO.puts "block: #{block}"
            raise e
        catch
          e ->
            IO.puts "Failed to precompile content_for block in '#{template}'"
            IO.puts "block: #{block}"
            raise e
        end
      template_atom = String.to_atom(template)
      name = String.to_atom(key)
      args = [template_atom, name, Macro.var(:params, nil), Macro.var(:context, nil)]

      # Define a method with the content_for block
      def content_for(unquote_splicing(args)) do
        _params = var!(params)
        _context = var!(context)
        unquote(compiled)
      end
    end
    [cf_def, cleaned]
  end

  def extract_content_for_blocks(template, body) do
    [head | parts] = String.split(body, ~r{(?<=\n|^)- content_for(?=(\s+\:\w+|\(\:\w+\))\n)})
    {content_fors, cleaned_parts} = Enum.reduce(parts, {[], []}, fn (part, {cfs, ps}) ->
      [new_cf, cleaned] = extract_content_for_block(template, part)
      {cfs ++ [new_cf], ps ++ cleaned}
    end)

    content_for_catchall = quote bind_quoted: [template: template] do
      # When no matching `content_for` is found for a yield_content, return ""
      template_atom = String.to_atom(template)
      # args = [template_atom, Macro.var(:_key, nil), Macro.var(:_params, nil), Macro.var(:_context, nil)]
      args = [template_atom, :head, Macro.var(:_params, nil), Macro.var(:_context, nil)]
      def content_for(unquote_splicing(args)) do
        ""
      end
    end
    [content_fors ++ [content_for_catchall], Enum.join([head] ++ cleaned_parts, "\n")]
  end

  def parse_template(template) do
    [frontmatter, body] = File.read(full_template_path(template))
    |> split_template

    [content_fors, body] = extract_content_for_blocks(template, body)

    # Strip leading space, or EEx compilation fails
    body = String.replace(body, ~r/^[\s\r\n]*/, "")

    [frontmatter, body, content_fors]
  end

  defp split_template({:ok, source = "---\n" <> _rest}) do
    [_, frontmatter_yaml, body] = String.split(source, "---\n")
    frontmatter = YamlElixir.read_from_string(frontmatter_yaml)
    [Macro.escape(frontmatter, unquote: true), body]
  end
  defp split_template({:ok, body}) do
    [Macro.escape(%{}, unquote: true), body]
  end

  defp full_template_path(path) do
    Path.join(source_path(), path)
  end
end
