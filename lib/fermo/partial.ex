defmodule Fermo.Partial do
  defmacro partial(path, param_overrides \\ nil, opts \\ nil) do
    module =
      path
      |> Mix.Fermo.Paths.absolute_to_source()
      |> Fermo.Naming.source_path_to_module()

    quote do
      template_params = var!(params) || %{}
      context = var!(context)
      page = context[:page]
      if page[:live] do
        page_path = context.page.path
        template_source_path = apply(unquote(module), :template_source_path, [])
        {:ok} = Fermo.Live.Dependencies.add_page_dependency(page_path, template_source_path)
      end
      opts = unquote(opts) || []
      po = unquote(param_overrides)
      param_overrides = if po, do: po, else: %{}
      content = opts[:do]
      params = Map.merge(template_params, param_overrides)
      p = if content do
        put_in(params, [:content], content)
      else
        params
      end

      Fermo.Template.render_template(unquote(module), unquote(path), page, p)
    end
  end
end
