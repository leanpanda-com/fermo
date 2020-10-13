defmodule Fermo.Template do
  import Fermo.Naming, only: [source_path_to_module: 1]
  import Mix.Fermo.Paths, only: [absolute_to_source: 1]

  def defaults_for(module) do
    apply(module, :defaults, [])
    |> Enum.into(
      %{},
      fn {key, value} ->
        {String.to_atom(key), value}
      end
    )
  end

  def params_for(module, page) do
    defaults = defaults_for(module)
    Map.merge(defaults, page.params)
  end

  def render_template(module, template, page, params \\ %{}) do
    context = build_context(module, template, page)
    apply(module, :call, [params, context])
  end

  def build_context(module, template, page) do
    env = System.get_env()
    %{
      module: module,
      template: template,
      page: page,
      env: env
    }
  end

  def module_for_template(template) do
    template
    |> absolute_to_source()
    |> source_path_to_module()
  end
end
