defmodule Fermo.YieldContent do
  defmacro yield_content(key) do
    quote do
      params = var!(params)
      context = var!(context)
      page = context.page
      template = page.template
      module =
        template
        |> Mix.Fermo.Paths.absolute_to_source()
        |> Fermo.Naming.source_path_to_module()
      apply(module, :content_for, [:"#{unquote(key)}", params, context])
    end
  end
end
