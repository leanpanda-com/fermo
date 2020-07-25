defmodule Fermo do
  require EEx
  require Slime
  import Fermo.Naming
  import Mix.Fermo.Paths

  @source_path "priv/source"

  def start(_start_type, _args \\ []) do
    {:ok} = FermoHelpers.start_link([:assets, :i18n])
    {:ok, self()}
  end

  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo

      @before_compile Fermo
      Module.register_attribute __MODULE__, :config, persist: true
      @config unquote(opts)

      import FermoHelpers.Assets
      import FermoHelpers.DateTime
      import FermoHelpers.I18n
      import FermoHelpers.Links
      import FermoHelpers.String
      import FermoHelpers.Text

      def environment, do: "production" # TODO
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def initial_config() do
        config = hd(__MODULE__.__info__(:attributes)[:config])

        build_path = config[:build_path] || "build"
        pages = config[:pages] || []
        statics = config[:statics] || []

        config
        |> put_in([:build_path], build_path)
        |> put_in([:pages], pages)
        |> put_in([:statics], statics)
        |> Fermo.Localizable.add()
        |> Fermo.Simple.add()
        |> put_in([:stats], %{})
        |> put_in([:stats, :start], Time.utc_now)
      end
    end
  end

  def page(config, template, target, params \\ nil, options \\ nil) do
    Fermo.add_page(config, template, target, params, options)
  end

  def paginate(config, template, options \\ %{}, context \\ %{}, fun \\ nil) do
    Fermo.Pagination.paginate(config, template, options, context, fun)
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

  def build(config) do
    {:ok} = FermoHelpers.build_assets()
    {:ok} = FermoHelpers.load_i18n()

    build_path = get_in(config, [:build_path])
    File.mkdir(build_path)

    copy_statics(config)
    if config[:sitemap] do
      Fermo.Sitemap.build(config)
    end

    config = build_pages(config)

    {:ok, config}
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

  defp build_pages(config) do
    # TODO: check if Webpack assets are ready before building HTML
    build_path = get_in(config, [:build_path])

    Task.async_stream(
      config.pages,
      fn %{template: template, target: target} = page ->
        module = module_for_template(template)
        context = build_context(module, template, page)
        params = params_for(module, page)
        target_override = apply(module, :content_for, [:path, params, context])
        final_target = if target_override == "" do
          target
        else
          # Avoid extra whitespace introduced by templating
          String.replace(target_override, ~r/\n/, "")
        end
        pathname = Path.join(build_path, final_target)
        page = put_in(page, [:pathname], pathname)
        render_page(page, config)
      end,
      [timeout: :infinity]
    ) |> Enum.to_list

    config
    |> put_in([:stats, :pages_built], Time.utc_now)
  end

  defp render_page(page, config) do
    with {:ok, hash} <- cache_key(page),
      {:ok, cache_pathname} <- cached_page_path(hash),
      {:ok} <- is_cached?(cache_pathname) do
      copy_file(cache_pathname, page.pathname)
    else
      {:build_and_cache, cache_pathname} ->
        body = inner_render_page(page, config)
        save_file(cache_pathname, body)
        save_file(page.pathname, body)
      _ ->
        body = inner_render_page(page, config)
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

  defp inner_render_page(%{template: template} = page, config) do
    module = module_for_template(template)
    defaults = defaults_for(module)

    layout = if Map.has_key?(defaults, "layout") do
      if defaults["layout"] do
        defaults["layout"] <> ".html.slim"
      else
        defaults["layout"]
      end
    else
      if Map.has_key?(config, :layout) do
        config.layout
      else
        "layouts/layout.html.slim"
      end
    end

    content = render_body(module, page)

    if layout do
      build_layout_with_content(layout, content, page)
    else
      content
    end
  end

  defp copy_file(source, destination) do
    path = Path.dirname(destination)
    File.mkdir_p(path)
    {:ok, _files} = File.cp_r(source, destination)
  end

  defp save_file(pathname, body) do
    path = Path.dirname(pathname)
    File.mkdir_p(path)
    File.write!(pathname, body, [:write])
  end

  defp defaults_for(module) do
    apply(module, :defaults, [])
  end

  defp params_for(module, page) do
    defaults = defaults_for(module)
    Map.merge(defaults, page.params)
  end

  defp render_body(module, %{template: template} = page) do
    params = params_for(module, page)
    render_template(module, template, page, params)
  end

  def render_template(module, template, page, params \\ %{}) do
    context = build_context(module, template, page)
    apply(module, :call, [params, context])
  end

  defp build_context(module, template, page) do
    env = System.get_env()
    %{
      module: module,
      template: template,
      page: page,
      env: env
    }
  end

  defp build_layout_with_content(layout, content, page) do
    module = module_for_template(layout)
    layout_params = Map.merge(page.params, %{content: content})
    render_template(module, layout, page, layout_params)
  end

  def full_template_path(path) do
    Path.join(@source_path, path)
  end

  def module_for_template(template) do
    template
    |> absolute_to_source()
    |> source_path_to_module()
  end
end
