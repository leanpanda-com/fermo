defmodule Fermo do
  require EEx
  require Slime

  @source_path "priv/source"

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
        |> put_in([:build_path], "build")
        |> put_in([:pages], [])
        |> put_in([:statics], [])
        |> put_in([:stats], %{})
        |> put_in([:stats, :start], Time.utc_now)
      end

      # When no matching `content_for` is found for a yield_content, return ""
      def content_for(_template, _key, _params, _context) do
        ""
      end
    end
    defs ++ [get_config]
  end

  def proxy(config, template, target, params \\ nil, options \\ nil) do
    Fermo.add_page(config, template, target, params, options)
  end

  def paginate(config, template, options \\ %{}, context \\ %{}, fun \\ nil) do
    Fermo.Pagination.paginate(config, template, options, context, fun)
  end

  def deftemplate(template) do
    [frontmatter, body, content_fors] = parse_template(template)

    eex_source = precompile_slim(body, template)

    defs = quote bind_quoted: binding() do
      info = [file: template, line: 1]
      compiled = EEx.compile_string(eex_source, info)
      escaped_frontmatter = Macro.escape(frontmatter)
      args = [Macro.var(:params, nil), Macro.var(:context, nil)]
      name = String.to_atom(template)

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

  def render_template(module, template, page, params \\ %{}) do
    context = %{
      module: module,
      template: template,
      page: page
    }
    name = String.to_atom(template)
    apply(module, name, [params, context])
  end

  def add_page(config, template, target, params \\ %{}, options \\ %{}) do
    pages = Map.get(config, :pages, [])
    page = page_from(template, target, params, options)
    put_in(config, [:pages], pages ++ [page])
  end

  def add_static(config, source, target) do
    statics = Map.get(config, :statics)
    put_in(config, [:statics], statics ++ [%{source: source, target: target}])
  end

  def page_from(template, target, params \\ %{}, options \\ %{}) do
    %{
      template: template,
      target: target,
      params: params,
      options: options
    }
  end

  defmacro build(config) do
    quote bind_quoted: binding() do
      Fermo.do_build(__MODULE__, config)
    end
  end

  def do_build(module, config) do
    Fermo.Helpers.I18n.load!(config)

    build_path = get_in(config, [:build_path])
    File.mkdir(build_path)
    copy_statics(config)

    built_pages = Enum.map(
      config.pages,
      fn %{target: target} = page ->
        pathname = Path.join(build_path, target)
        page = put_in(page, [:pathname], pathname)
        Task.async(fn -> render_page(module, page) end)
      end
    )
    |> Enum.map(&Task.await(&1, 600000))

    put_in(config, [:stats, :pages_built], Time.utc_now)
    |> put_in([:pages], built_pages)
  end

  defp copy_statics(config) do
    statics = config[:statics]
    build_path = get_in(config, [:build_path])
    Enum.each(statics, fn (%{source: source, target: target}) ->
      source_pathname = Path.join(@source_path, source)
      target_pathname = Path.join(build_path, target)
      File.cp_r(source_pathname, target_pathname)
    end)
  end

  defp precompile_slim(body, template, type \\ "template") do
    try do
      Slime.Renderer.precompile(body)
    rescue
      e in Slime.TemplateSyntaxError ->
        line = e.line_number
        IO.puts "Failed to precompile #{type} in '#{template}' at line #{line}"
        IO.puts "body:\n#{body}\n\n"
        raise e
    end
  end

  defp render_page(module, %{template: template, pathname: pathname} = page) do
    defaults_method = String.to_atom(template <> "-defaults")
    defaults = apply(module, defaults_method, [])
    layout = if Map.has_key?(defaults, "layout") do
      defaults["layout"]
    else
      "layout.html.slim" # TODO: make this a setting
    end
    content = render_body(module, page, defaults)
    body = if layout do
      build_layout_with_content(module, content, page, layout)
    else
      content
    end

    save_file(pathname, body)

    put_in(page, [:body], body)
  end

  defp save_file(pathname, body) do
    path = Path.dirname(pathname)
    File.mkdir_p(path)
    File.write!(pathname, body, [:write])
  end

  defp render_body(module, %{template: template, params: params} = page, defaults) do
    args = Map.merge(defaults, params)
    render_template(module, template, page, args)
  end

  defp build_layout_with_content(module, content, page, layout) do
    layout_template = "layouts/" <> layout
    layout_params = %{content: content}
    render_template(module, layout_template, page, layout_params)
  end

  defp extract_content_for_block(template, part) do
    # Extract the content_for block (until the next line that isn't indented)
    # TODO: the block should not stop at the first non-indented **empty** line,
    #   it should continue to the first non-indented line with text
    [key | [block | cleaned]] = Regex.run(~r/^(?:[\(\s]\:)([^\n\)]+)\)?\n((?:\s{2}[^\n]+\n)+)(.*)/s, part, capture: :all_but_first)
    # Strip leading blank lines
    block = String.replace(block, ~r/^[\s\r\n]*/, "", global: false)
    # Strip indentation
    block = String.replace(block, ~r/^  /m, "")

    eex_source = precompile_slim(block, template, "content_for block")

    cf_def = quote bind_quoted: [eex_source: eex_source, template: template, key: key] do
      info = [file: template, line: 1]
      compiled = EEx.compile_string(eex_source, info)
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

  defp extract_content_for_blocks(template, body) do
    [head | parts] = String.split(body, ~r{(?<=\n|^)- content_for(?=(\s+\:\w+|\(\:\w+\))\n)})
    {content_fors, cleaned_parts} = Enum.reduce(parts, {[], []}, fn (part, {cfs, ps}) ->
      [new_cf, cleaned] = extract_content_for_block(template, part)
      {cfs ++ [new_cf], ps ++ cleaned}
    end)
    [content_fors, Enum.join([head] ++ cleaned_parts, "\n")]
  end

  defp parse_template(template) do
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
    Path.join(@source_path, path)
  end
end
