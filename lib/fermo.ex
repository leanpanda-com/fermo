defmodule Fermo do
  require EEx
  require Slime

  defmodule FermoError do
    defexception [:message]
  end

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

      :yamerl_app.set_param(:node_mods, [])

      use Fermo.Helpers.Assets
      use Fermo.Helpers.Links
      use Fermo.Helpers.I18n
      use Fermo.Helpers.Text
      import FermoHelpers.DateTime
      import FermoHelpers.String

      defmacro partial(path, params \\ nil, opts \\ nil) do
        dirname = Path.dirname(path)
        basename = Path.basename(path)
        template = if dirname == "." do
          "_#{basename}.html.slim"
        else
          Path.join(dirname, "_#{basename}.html.slim")
        end
        quote do
          context = var!(context)
          page = context[:page]
          opts = unquote(opts) || []
          content = opts[:content]
          p = if content do
            put_in(unquote(params) || %{}, [:content], content)
          else
            unquote(params) || %{}
          end
          Fermo.render_template(__MODULE__, unquote(template), page, p)
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
    build_path = config[:build_path] || "build"
    pages = config[:pages] || []
    statics = config[:statics] || []

    config =
      config
      |> put_in([:build_path], build_path)
      |> put_in([:pages], pages)
      |> put_in([:statics], statics)
      |> put_in([:stats], %{})

    config = Fermo.Localizable.add(config)
    config = Fermo.Simple.add(config)

    templates = File.cd!(@source_path, fn ->
      Path.wildcard("**/*.slim")
    end)
    defs = Enum.map(templates, fn (path) ->
      Fermo.deftemplate(path)
    end)

    Module.put_attribute(env.module, :config, config)

    get_config = quote do
      def config() do
        hd(__MODULE__.__info__(:attributes)[:config])
        |> put_in([:stats, :start], Time.utc_now)
      end

      # When no matching `content_for` is found for a yield_content, return ""
      def content_for(_template, _key, _params, _context) do
        ""
      end
    end

    defs ++ [get_config]
  end

  def page(config, template, target, params \\ nil, options \\ nil) do
    Fermo.add_page(config, template, target, params, options)
  end

  def paginate(config, template, options \\ %{}, context \\ %{}, fun \\ nil) do
    Fermo.Pagination.paginate(config, template, options, context, fun)
  end

  def deftemplate(template) do
    {frontmatter, content_fors, removed, body} = parse_template(template)

    eex_source = precompile_slim(body, template)

    full_template_path = Fermo.full_template_path(template)

    # We do a first compilation here so we can trap errors
    # and give a better message
    try do
      EEx.compile_string(eex_source, line: removed, file: full_template_path)
    rescue
      e in TokenMissingError ->
        message = """
        Template compilation error: #{e.description}
        Path: '#{full_template_path}'
        """
        raise FermoError, message: message
    end

    defs = quote bind_quoted: binding(), file: full_template_path do
      compiled = EEx.compile_string(eex_source, line: removed, file: full_template_path)
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
    env = System.get_env()
    context = %{
      module: module,
      template: template,
      page: page,
      env: env
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

    build_pages(module, config)
  end

  defp copy_statics(config) do
    statics = config[:statics]
    build_path = get_in(config, [:build_path])
    Enum.each(statics, fn (%{source: source, target: target}) ->
      source_pathname = Path.join(@source_path, source)
      target_pathname = Path.join(build_path, target)
      copy_file(source_pathname, target_pathname)
    end)
  end

  defp build_pages(module, config) do
    # TODO: check if Webpack assets are ready before building HTML
    build_path = get_in(config, [:build_path])

    built = Task.async_stream(
      config.pages,
      fn %{target: target} = page ->
        pathname = Path.join(build_path, target)
        page = put_in(page, [:pathname], pathname)
        render_page(module, page)
      end,
      [timeout: :infinity]
    ) |> Enum.to_list

    config
    |> put_in([:stats, :pages_built], Time.utc_now)
    |> put_in([:pages], built)
  end

  defp render_page(module, page) do
    with {:ok, hash} <- cache_key(page),
      {:ok, cache_pathname} <- cached_page_path(hash),
      {:ok} <- is_cached?(cache_pathname) do
      copy_file(cache_pathname, page.pathname)
    else
      {:build_and_cache, cache_pathname} ->
        body = inner_render_page(module, page)
        save_file(cache_pathname, body)
        save_file(page.pathname, body)
      _ ->
        body = inner_render_page(module, page)
        save_file(page.pathname, body)
    end
  end

  defp cache_key(%{options: %{surrogate_key: surrogate_key}}) do
    hash = :crypto.hash(:sha256, surrogate_key) |> Base.encode16
    {:ok, hash}
  end
  defp cache_key(_page), do: {:no_key}

  defp cached_page_path(hash) do
    {:ok, Path.join("tmp/page_cache", hash)}
  end

  defp is_cached?(cached_pathname) do
    if File.exists?(cached_pathname) do
      {:ok}
    else
      {:build_and_cache, cached_pathname}
    end
  end

  defp inner_render_page(module, %{template: template, pathname: pathname} = page) do
    defaults_method = String.to_atom(template <> "-defaults")
    defaults = apply(module, defaults_method, [])
    layout = if Map.has_key?(defaults, "layout") do
      if defaults["layout"] do
        defaults["layout"] <> ".html.slim"
      else
        defaults["layout"]
      end
    else
      "layout.html.slim" # TODO: make this a setting
    end
    content = render_body(module, page, defaults)
    if layout do
      build_layout_with_content(module, content, page, layout)
    else
      content
    end
  end

  defp copy_file(source, destination) do
    path = Path.dirname(destination)
    File.mkdir_p(path)
    File.cp(source, destination)
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

  defp precompile_slim(body, template, type \\ "template") do
    try do
      Slime.Renderer.precompile(body)
    rescue
      e in Slime.TemplateSyntaxError ->
        line = e.line_number
        pathname = full_template_path(template)
        message = """
        SLIM template error: #{e.message}
        Template type: #{type}
        Path: '#{pathname}', line #{line + 1}

        #{body}
        """
        raise FermoError, message: message
    end
  end

  defp parse_template(template) do
    [frontmatter, body] =
      File.read(full_template_path(template))
      |> split_template

    {content_fors, removed, body} = extract_content_for_blocks(template, body)

    # Strip leading space, or EEx compilation fails
    body = String.replace(body, ~r/^[\s\r\n]*/, "")

    {frontmatter, content_fors, removed, body}
  end

  defp extract_content_for_blocks(template, body) do
    [head | parts] = String.split(body, ~r{(?<=\n|^)- content_for(?=(\s+\:\w+|\(\:\w+\))\n)})
    {content_fors, removed, cleaned_parts} = Enum.reduce(parts, {[], 0, []}, fn (part, {cfs, removed, ps}) ->
      {new_cf, lines, cleaned} = extract_content_for_block(template, part)
      {cfs ++ [new_cf], removed + lines, ps ++ cleaned}
    end)
    {content_fors, removed, Enum.join([head] ++ cleaned_parts, "\n")}
  end

  defp extract_content_for_block(template, part) do
    # Extract the content_for block (until the next line that isn't indented)
    # TODO: the block should not stop at the first non-indented **empty** line,
    #   it should continue to the first non-indented line with text
    [key | [block | cleaned]] = Regex.run(~r/^(?:[\(\s]\:)([^\n\)]+)\)?\n((?:\s{2}[^\n]+\n)+)(.*)/s, part, capture: :all_but_first)
    lines = count_lines(block) + 1
    # Strip leading blank lines
    block = String.replace(block, ~r/^[\s\r\n]*/, "", global: false)
    # Strip indentation
    block = String.replace(block, ~r/^  /m, "")

    eex_source = precompile_slim(block, template, "content_for block")

    full_template_path = Fermo.full_template_path(template)
    cf_def = quote bind_quoted: binding(), file: full_template_path do
      compiled = EEx.compile_string(eex_source)
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

    {cf_def, lines, cleaned}
  end

  defp count_lines(text), do: length(String.split(text, "\n"))

  defp split_template({:ok, source = "---\n" <> _rest}) do
    [_, frontmatter_yaml, body] = String.split(source, "---\n")
    frontmatter = YamlElixir.read_from_string(frontmatter_yaml)
    [Macro.escape(frontmatter, unquote: true), body]
  end
  defp split_template({:ok, body}) do
    [Macro.escape(%{}, unquote: true), body]
  end

  def full_template_path(path) do
    Path.join(@source_path, path)
  end
end
