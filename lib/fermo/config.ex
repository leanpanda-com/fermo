defmodule Fermo.Config do
  @moduledoc false

  @i18n Application.get_env(:fermo, :i18n, Fermo.I18n)
  @localizable Application.get_env(:fermo, :localizable, Fermo.Localizable)
  @simple Application.get_env(:fermo, :simple, Fermo.Simple)
  @template Application.get_env(:fermo, :template, Fermo.Template)

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
        |> merge_defaults(config)
      end
    )

    config
    |> put_in([:pages], pages)
    |> @i18n.optionally_build_path_map()
    |> put_in([:stats, :post_config_completed], Time.utc_now)
  end

  def add_page(config, template, target, params \\ %{}) do
    pages = Map.get(config, :pages, [])
    page = page_from(template, target, params)
    put_in(config, [:pages], pages ++ [page])
  end

  def add_static(config, source, target) do
    statics = Map.get(config, :statics)
    put_in(config, [:statics], statics ++ [%{source: source, target: target}])
  end

  def page_from(template, target, params) do
    %{
      template: template,
      target: target,
      params: params
    }
  end

  defp set_path(page, config) do
    %{template: template, target: supplied_target} = page
    module = @template.module_for_template(template)
    context = @template.build_context(module, template, page)
    params = @template.params_for(module, page)
    path_override = @template.content_for(module, [:path, params, context])
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

  defp optionally_add_extensions(nil), do: nil
  defp optionally_add_extensions(layout), do: "#{layout}.html.slim"

  defp merge_defaults(page, config) do
    template = page.template
    module = @template.module_for_template(template)
    defaults = @template.defaults_for(module)

    layout = cond do
      Map.has_key?(page.params, :layout) ->
        optionally_add_extensions(page.params.layout)
      Map.has_key?(defaults, :layout) ->
        optionally_add_extensions(defaults.layout)
      Map.has_key?(config, :layout) ->
        optionally_add_extensions(config.layout)
      true ->
        "layouts/layout.html.slim"
    end

    params =
      defaults
      |> Map.merge(page[:params] || %{})
      |> put_in([:module], module)
      |> put_in([:layout], layout)

    put_in(page, [:params], params)
  end
end
