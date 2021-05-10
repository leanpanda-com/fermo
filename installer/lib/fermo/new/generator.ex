defmodule Fermo.New.Generator do
  defmacro __using__(_env) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    root = Path.expand("../../../templates/new", __DIR__)
    templates = Module.get_attribute(env.module, :templates)
    templates_ast =
      for source <- templates do
        path = Path.join(root, source)
        compiled = EEx.compile_file(path)
        quote do
          @external_resource unquote(path)
          @file unquote(path)
          def render(unquote(source), var!(assigns))
          when is_list(var!(assigns)),
            do: unquote(compiled)
        end
      end

    quote do
      unquote(templates_ast)
    end
  end
end
