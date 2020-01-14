defmodule Fermo.Partial do
  import Fermo.Naming
  import Mix.Fermo.Paths

  defmacro partial(path, params \\ nil, opts \\ nil) do
    module =
      path
      |> Mix.Fermo.Paths.absolute_to_source()
      |> Fermo.Naming.source_path_to_module()

    quote do
      context = var!(context)
      page = context[:page]
      opts = unquote(opts) || []
      content = opts[:content]
      p = if content do
        put_in(unquote(params) || %{}, [:content], content)
      else
        unquote(params) || %{}
      end

      Fermo.render_template(unquote(module), unquote(path), page, p)
    end
  end
end
