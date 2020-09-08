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

  def template_to_target(template, opts) do
    String.replace(template, ".slim", "")
    |> path_to_target(opts)
  end

  def path_to_target(path, opts \\ [])
  def path_to_target(path, as_index_html: false), do: path
  def path_to_target(path, _opts) do
    cond do
      path == "index.html" -> path
      String.ends_with?(path, "/index.html") -> path
      String.ends_with?(path, ".html") ->
        String.replace(path, ".html", "/index.html")
      true ->
        path <> "/index.html"
    end
  end

  def target_to_path(target) do
    cond do
      target == "index.html" -> "/"
      String.ends_with?(target, "/index.html") ->
        String.replace(target, "index.html", "")
      true -> target
    end
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
    config = put_in(config, [:stats, :build_started], Time.utc_now)

    {:ok} = FermoHelpers.build_assets()
    {:ok} = FermoHelpers.load_i18n()

    build_path = get_in(config, [:build_path])
    File.mkdir(build_path)

    config =
      config
      |> copy_statics()
      |> set_paths()
      |> Fermo.Sitemap.build()
      |> merge_default_options()
      |> Fermo.I18n.optionally_build_path_map()
      |> build_pages()

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
    put_in(config, [:stats, :copy_statics_completed], Time.utc_now)
  end

  defp set_paths(config) do
    build_path = get_in(config, [:build_path])

    pages = Enum.map(
      config.pages,
      fn %{template: template, target: supplied_target} = page ->
        module = module_for_template(template)
        context = build_context(module, template, page)
        params = params_for(module, page)
        path_override = apply(module, :content_for, [:path, params, context])
        # This depends on the default content_for returning "" and not nil
        [target, path] = if path_override == "" do
          [supplied_target, target_to_path(supplied_target)]
        else
          # Avoid extra whitespace introduced by templating
          path = String.replace(path_override, ~r/\n/, "")
          [path_to_target(path, as_index_html: true), path]
        end

        pathname = Path.join(build_path, target)

        page
        |> put_in([:target], target)
        |> put_in([:path], path)
        |> put_in([:pathname], pathname)
      end
    )

    config
    |> put_in([:pages], pages)
    |> put_in([:stats, :set_paths_completed], Time.utc_now)
  end

  defp merge_default_options(config) do
    pages = Enum.map(
      config.pages,
      fn %{template: template} = page ->
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

        options =
          defaults
          |> Map.merge(page.options || %{})
          |> put_in([:module], module)
          |> put_in([:layout], layout)

        put_in(page, [:options], options)
      end
    )

    config
    |> put_in([:pages], pages)
    |> put_in([:stats, :merge_default_options_completed], Time.utc_now)
  end

  defp build_pages(config) do
    # TODO: check if Webpack assets are ready before building HTML
    # TODO: avoid passing config into tasks - decide the layout beforehand

    Task.async_stream(
      config.pages,
      &(render_page(&1)),
      [timeout: :infinity]
    ) |> Enum.to_list

    config
    |> put_in([:stats, :build_pages_completed], Time.utc_now)
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

  defp inner_render_page(page) do
    content = render_body(page.options.module, page)

    if page.options.layout do
      build_layout_with_content(page.options.layout, content, page)
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
    |> Enum.into(
      %{},
      fn {key, value} ->
        {String.to_atom(key), value}
      end
    )
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
