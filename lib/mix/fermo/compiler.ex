defmodule Mix.Fermo.Compiler do
  import Fermo.Naming
  import Mix.Fermo.Paths
  alias Mix.Fermo.Compiler.Manifest

  def run() do
    compilation_timestamp = compilation_timestamp()
    all_sources = all_sources()
    changed = changed_since(all_sources, Manifest.timestamp())
    Enum.each(changed, &compile_file/1)
    Manifest.write(all_sources, compilation_timestamp)
  end

  defp compile_file(template) do
    module =
      template
      |> absolute_to_source()
      |> source_path_to_module()

    {frontmatter, content_fors, removed, body} = parse_template(template)

    eex_source = precompile_slim(body, template)

    # We do a first compilation here so we can trap errors
    # and give a better message
    try do
      EEx.compile_string(eex_source, line: removed, file: template)
    rescue
      e in TokenMissingError ->
        message = """
        Template compilation error: #{e.description}
        Path: '#{template}'
        """
        raise Fermo.Error, message: message
    end

    quoted_module = quote bind_quoted: binding(), file: template do
      compiled = EEx.compile_string(eex_source, line: removed, file: template)
      escaped_frontmatter = Macro.escape(frontmatter)
      args = [Macro.var(:params, nil), Macro.var(:context, nil)]
      name = String.to_atom(template)

      defmodule :"#{module}" do
        # content_fors

        def page_moods(_locale), do: []
        def published_moods(_locale), do: []

        # Define a method with the frontmatter, so we can merge with
        # params when the template is evaluated
        def defaults() do
          unquote(escaped_frontmatter)
        end

        def call(unquote_splicing(args)) do
          _params = var!(params)
          _context = var!(context)
          unquote(compiled)
        end
      end
    end
    # foo = Macro.to_string(quoted_module)
    # IO.puts "foo: #{foo}"

    compiled_modules = Code.compile_quoted(quoted_module)
    IO.puts "compiled_modules: #{inspect(compiled_modules, [pretty: true, width: 0])}"
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

    {content_fors, removed, body} = extract_content_for_blocks(template, body)

    # Strip leading space, or EEx compilation fails
    body = String.replace(body, ~r/^[\s\r\n]*/, "")

    {frontmatter, content_fors, removed, body}
  end

  defp extract_content_for_blocks(template, body) do
    [head | parts] = String.split(body, ~r{(?<=\n|^)- content_for(?=(\s+\:\w+|\(\:\w+\))\n)})
    {content_fors, removed, cleaned_parts} = Enum.reduce(parts, {[], 0, []}, fn (part, {cfs, removed, ps}) ->
      {new_cf, lines, cleaned} = extract_content_for_block(template, part)
      {cfs ++ [new_cf], removed + lines, ps ++ cleaned}
    end)
    {content_fors, removed, Enum.join([head] ++ cleaned_parts, "\n")}
  end

  defp extract_content_for_block(template, part) do
    # Extract the content_for block (until the next line that isn't indented)
    # TODO: the block should not stop at the first non-indented **empty** line,
    #   it should continue to the first non-indented line with text
    [key | [block | cleaned]] = Regex.run(~r/^(?:[\(\s]\:)([^\n\)]+)\)?\n((?:\s{2}[^\n]+\n)+)(.*)/s, part, capture: :all_but_first)
    lines = count_lines(block) + 1
    # Strip leading blank lines
    block = String.replace(block, ~r/^[\s\r\n]*/, "", global: false)
    # Strip indentation
    block = String.replace(block, ~r/^  /m, "")

    eex_source = precompile_slim(block, template, "content_for block")

    full_template_path = Fermo.full_template_path(template)
    cf_def = quote bind_quoted: binding(), file: full_template_path do
      compiled = EEx.compile_string(eex_source)
      template_atom = String.to_atom(template)
      name = String.to_atom(key)
      args = [template_atom, name, Macro.var(:params, nil), Macro.var(:context, nil)]

      # Define a method with the content_for block
      def content_for(unquote_splicing(args)) do
        _params = var!(params)
        _context = var!(context)
        unquote(compiled)
      end
    end

    {cf_def, lines, cleaned}
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

  defp changed_since(paths, timestamp) do
    Enum.filter(paths, &(Mix.Utils.last_modified(&1) > timestamp))
  end

  defp all_sources do
    Mix.Utils.extract_files([full_source_path()], [:slim])
    |> MapSet.new()
  end

  def compilation_timestamp, do: System.os_time(:second)
end
