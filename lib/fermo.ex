defmodule Fermo do
  require EEx
  require Slime
  import Fermo.Naming
  import Mix.Fermo.Paths

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
      import FermoHelpers.DateTime
      import FermoHelpers.String

      def environment, do: "production" # TODO
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

    Module.put_attribute(env.module, :config, config)

    get_config = quote do
      def config() do
        hd(__MODULE__.__info__(:attributes)[:config])
        |> put_in([:stats, :start], Time.utc_now)
      end
    end

    get_config
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
    Fermo.Helpers.I18n.load!()

    build_path = get_in(config, [:build_path])
    File.mkdir(build_path)

    copy_statics(config)

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

    built = Task.async_stream(
      config.pages,
      fn %{target: target} = page ->
        pathname = Path.join(build_path, target)
        page = put_in(page, [:pathname], pathname)
        render_page(page)
      end,
      [timeout: :infinity]
    ) |> Enum.to_list

    config
    |> put_in([:stats, :pages_built], Time.utc_now)
    |> put_in([:pages], built)
  end

  defp render_page(page) do
    with {:ok, hash} <- cache_key(page),
      {:ok, cache_pathname} <- cached_page_path(hash),
      {:ok} <- is_cached?(cache_pathname) do
      copy_file(cache_pathname, page.pathname)
    else
      {:build_and_cache, cache_pathname} ->
        body = inner_render_page(page)
        save_file(cache_pathname, body)
        save_file(page.pathname, body)
      _ ->
        body = inner_render_page(page)
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

  defp inner_render_page(%{template: template} = page) do
    module = module_for_template(template)
    defaults = apply(module, :defaults, [])

    layout = if Map.has_key?(defaults, "layout") do
      if defaults["layout"] do
        defaults["layout"] <> ".html.slim"
      else
        defaults["layout"]
      end
    else
      "layouts/layout.html.slim" # TODO: make this a setting
    end

    content = render_body(module, page, defaults)

    if layout do
      build_layout_with_content(layout, content, page)
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

  def render_template(module, template, page, params \\ %{}) do
    env = System.get_env()
    context = %{
      module: module,
      template: template,
      page: page,
      env: env
    }
    apply(module, :call, [params, context])
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
