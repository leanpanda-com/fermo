defmodule Fermo.Template do
  @moduledoc """
  Handle Fermo templates
  """

  import Fermo.Naming, only: [source_path_to_module: 1]
  import Mix.Fermo.Paths, only: [absolute_to_source: 1]

  @callback defaults_for(module()) :: map()
  def defaults_for(module) do
    apply(module, :defaults, [])
    |> Enum.into(
      %{},
      fn {key, value} ->
        {String.to_atom(key), value}
      end
    )
  end

  @callback params_for(module(), map()) :: map()
  def params_for(module, page) do
    defaults = defaults_for(module)
    Map.merge(defaults, page.params)
  end

  def render_template(module, template, page, params \\ %{}) do
    context = build_context(module, template, page)
    apply(module, :call, [params, context])
  end

  @callback build_context(module(), String.t(), map()) :: map()
  def build_context(module, template, page) do
    env = System.get_env()
    %{
      module: module,
      template: template,
      page: page,
      env: env
    }
  end

  @callback module_for_template(String.t()) :: module()
  def module_for_template(template) do
    template
    |> absolute_to_source()
    |> source_path_to_module()
  end

  @callback content_for(module(), [term()]) :: term()
  def content_for(module, args), do: apply(module, :content_for, args)
end
