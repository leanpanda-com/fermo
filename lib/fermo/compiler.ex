defmodule Fermo.Compiler do
  import Mix.Fermo.Paths
  import Fermo.Naming

  @callback compile(String.t()) :: {:ok}
  def compile(template_project_path) do
    template_source_path = absolute_to_source(template_project_path)

    module = source_path_to_module(template_source_path)

    {frontmatter, content_fors, offset, body} = parse_template(template_project_path)

    eex_source = precompile_slim(body, template_project_path)

    # We do a first compilation here so we can trap errors
    # and give a better message
    try do
      EEx.compile_string(eex_source, line: offset, file: template_project_path)
    rescue
      e in TokenMissingError ->
        message = """
        Template compilation error: #{e.description}
        Path: '#{template_project_path}'
        """
        raise Fermo.Error, message: message
    end

    cfs_eex = Enum.map(content_fors, fn [key, block, offset] ->
      eex = precompile_slim(block, template_project_path, "content_for(:#{key})")
      [key, eex, offset]
    end)

    quoted_module = quote bind_quoted: binding(), file: template_project_path do
      compiled = EEx.compile_string(eex_source, line: offset, file: template_project_path)

      cfs_compiled = Enum.map(cfs_eex, fn [key, eex, offset] ->
        cf_compiled = EEx.compile_string(eex, line: offset, file: template_project_path)
        {key, cf_compiled}
      end)

      defmodule :"#{module}" do
        use Helpers
        require Fermo.Partial
        import Fermo.Partial
        require Fermo.YieldContent
        import Fermo.YieldContent
        require Fermo.Assets
        import Fermo.Assets
        import Fermo.I18n

        Enum.map(cfs_compiled, fn {key, cf_compiled} ->
          args = [:"#{key}", Macro.var(:params, nil), Macro.var(:context, nil)]

          def content_for(unquote_splicing(args)) do
            _params = var!(params)
            _context = var!(context)
            unquote(cf_compiled)
          end
        end)

        # TODO: Shouldn't this return nil?
        # TODO: if we change this to return nil,
        #   we need to update set_paths/1
        def content_for(key, params, context) do
          ""
        end

        def template_source_path() do
          unquote(template_source_path)
        end

        # Define a method with the frontmatter, so we can merge with
        # params when the template is evaluated
        escaped_frontmatter = Macro.escape(frontmatter)

        def defaults() do
          unquote(escaped_frontmatter)
        end

        args = [Macro.var(:params, nil), Macro.var(:context, nil)]
        def call(unquote_splicing(args)) do
          _params = var!(params)
          _context = var!(context)
          unquote(compiled)
        end
      end
    end

    Code.compiler_options(ignore_module_conflict: true)
    [{module, bytecode} | _other] = Code.compile_quoted(quoted_module)
    Code.compiler_options(ignore_module_conflict: false)
    base = Mix.Project.compile_path()
    module_path = Path.join(base, "#{module}.beam")
    File.write!(module_path, bytecode, [:write])

    {:ok}
  end

  defp precompile_slim(body, template, type \\ "template") do
    try do
      Slime.Renderer.precompile(body)
    rescue
      e in Slime.TemplateSyntaxError ->
        line = e.line_number
        message = """
        SLIM template error: #{e.message}
        Template type: #{type}
        Path: '#{template}', line #{line + 1}

        #{body}
        """
        raise Fermo.Error, message: message
    end
  end

  defp parse_template(template) do
    [frontmatter, body] =
      File.read(template)
      |> split_template

    {content_fors, offset, body} = extract_content_for_blocks(body)

    # Strip leading space, or EEx compilation fails
    body = String.replace(body, ~r/^[\s\r\n]*/, "")

    {frontmatter, content_fors, offset, body}
  end

  defp extract_content_for_blocks(body) do
    [head | parts] = String.split(body, ~r{(?<=\n|^)- content_for(?=(\s+\:\w+|\(\:\w+\))\n)})
    {content_fors, offset, cleaned_parts} = Enum.reduce(parts, {[], 0, []}, fn (part, {cfs, offset, ps}) ->
      {new_cf, lines, cleaned} = extract_content_for_block(part, offset)
      {cfs ++ [new_cf], offset + lines, ps ++ cleaned}
    end)
    {content_fors, offset, Enum.join([head] ++ cleaned_parts, "\n")}
  end

  defp extract_content_for_block(part, offset) do
    # Extract the content_for block (until the next line that isn't indented)
    # TODO: the block should not stop at the first non-indented **empty** line,
    #   it should continue to the first non-indented line with text
    [key | [block | cleaned]] = Regex.run(~r/^(?:[\(\s]\:)([^\n\)]+)\)?\n((?:\s{2}[^\n]+\n)+)(.*)/s, part, capture: :all_but_first)
    lines = count_lines(block) + 1
    # Strip leading blank lines
    block = String.replace(block, ~r/^[\s\r\n]*/, "", global: false)
    # Strip indentation
    block = String.replace(block, ~r/^  /m, "")
    # Strip newlines at end
    block = String.replace(block, ~r/\n+\z/, "")

    {[key, block, offset], lines, cleaned}
  end

  defp count_lines(text), do: length(String.split(text, "\n"))

  defp split_template({:ok, source = "---\n" <> _rest}) do
    [_, frontmatter_yaml, body] = String.split(source, "---\n")
    frontmatter = YamlElixir.read_from_string(frontmatter_yaml)
    [Macro.escape(frontmatter, unquote: true), body]
  end
  defp split_template({:ok, body}) do
    [Macro.escape(%{}, unquote: true), body]
  end
end
