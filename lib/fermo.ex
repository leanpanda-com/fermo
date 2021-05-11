defmodule Fermo do
  require EEx
  require Slime
  import Mix.Fermo.Paths, only: [source_path: 0]

  def start(_start_type, _args \\ []) do
    {:ok, _pid} = Fermo.Assets.start_link()
    {:ok, _pid} = I18n.start_link()
    {:ok, self()}
  end

  @doc false
  defmacro __using__(opts \\ %{}) do
    quote do
      require Fermo

      @before_compile Fermo
      Module.register_attribute __MODULE__, :config, persist: true
      @config unquote(opts)

      import Fermo.Assets
      import I18n
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

    {:ok} = Fermo.Assets.build()
    {:ok} = Fermo.I18n.load()

    build_path = get_in(config, [:build_path])
    File.mkdir(build_path)

    config =
      config
      |> post_config()
      |> copy_statics()
      |> Fermo.Sitemap.build()
      |> Fermo.Build.run()

    {:ok, config}
  end

  defp copy_statics(config) do
    statics = config[:statics]
    build_path = get_in(config, [:build_path])
    Enum.each(statics, fn (%{source: source, target: target}) ->
      source_pathname = Path.join(source_path(), source)
      target_pathname = Path.join(build_path, target)
      Fermo.File.copy(source_pathname, target_pathname)
    end)
    put_in(config, [:stats, :copy_statics_completed], Time.utc_now)
  end

  def post_config(config) do
    pages = Enum.map(
      config.pages,
      fn page ->
        page
        |> set_path(config)
        |> merge_default_options(config)
      end
    )

    config
    |> put_in([:pages], pages)
    |> Fermo.I18n.optionally_build_path_map()
    |> put_in([:stats, :post_config_completed], Time.utc_now)
  end

  def set_path(page, config) do
    %{template: template, target: supplied_target} = page
    module = Fermo.Template.module_for_template(template)
    context = Fermo.Template.build_context(module, template, page)
    params = Fermo.Template.params_for(module, page)
    path_override = apply(module, :content_for, [:path, params, context])
    # This depends on the default content_for returning "" and not nil
    [target, path] = if path_override == "" do
      [supplied_target, target_to_path(supplied_target)]
    else
      # Avoid extra whitespace introduced by templating
      path = String.replace(path_override, ~r/\n/, "")
      [path_to_target(path, as_index_html: true), path]
    end

    pathname = Path.join(config.build_path, target)

    page
    |> put_in([:target], target)
    |> put_in([:path], path)
    |> put_in([:pathname], pathname)
  end

  def merge_default_options(page, config) do
    template = page.template
    module = Fermo.Template.module_for_template(template)
    defaults = Fermo.Template.defaults_for(module)

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
end
