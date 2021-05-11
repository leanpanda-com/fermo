defmodule Fermo.Config do
  @localizable Application.get_env(:fermo, :localizable, Fermo.Localizable)
  @simple Application.get_env(:fermo, :simple, Fermo.Simple)

  def initial(config) do
    build_path = config[:build_path] || "build"
    pages = config[:pages] || []
    statics = config[:statics] || []

    config
    |> put_in([:build_path], build_path)
    |> put_in([:pages], pages)
    |> put_in([:statics], statics)
    |> @localizable.add()
    |> @simple.add()
    |> put_in([:stats], %{})
    |> put_in([:stats, :start], Time.utc_now)
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

  def add_page(config, template, target, params \\ %{}, options \\ %{}) do
    pages = Map.get(config, :pages, [])
    page = page_from(template, target, params, options)
    put_in(config, [:pages], pages ++ [page])
  end

  def add_static(config, source, target) do
    statics = Map.get(config, :statics)
    put_in(config, [:statics], statics ++ [%{source: source, target: target}])
  end

  def page_from(template, target, params, options) do
    %{
      template: template,
      target: target,
      params: params,
      options: options
    }
  end

  defp set_path(page, config) do
    %{template: template, target: supplied_target} = page
    module = Fermo.Template.module_for_template(template)
    context = Fermo.Template.build_context(module, template, page)
    params = Fermo.Template.params_for(module, page)
    path_override = apply(module, :content_for, [:path, params, context])
    # This depends on the default content_for returning "" and not nil
    [target, path] = if path_override == "" do
      [supplied_target, Fermo.Paths.target_to_path(supplied_target)]
    else
      # Avoid extra whitespace introduced by templating
      path = String.replace(path_override, ~r/\n/, "")
      [Fermo.Paths.path_to_target(path, as_index_html: true), path]
    end

    pathname = Path.join(config.build_path, target)

    page
    |> put_in([:target], target)
    |> put_in([:path], path)
    |> put_in([:pathname], pathname)
  end

  defp merge_default_options(page, config) do
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
