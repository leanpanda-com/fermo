defmodule Fermo.Compilers.Slim do
  import Mix.Fermo.Paths
  import Fermo.Naming
  alias Fermo.Compilers.EEx

  @file_impl Application.get_env(:fermo, :file_impl, File)

  @callback compile(String.t()) :: {:ok}
  def compile(template_project_path) do
    template_source_path = absolute_to_source(template_project_path)

    name = source_path_to_module(template_source_path)

    {frontmatter, content_fors, offset, body} = parse_template(template_project_path)

    eex_source = precompile_slim(body, template_project_path)

    cfs_eex = Enum.map(content_fors, fn [key, block, offset] ->
      eex = precompile_slim(block, template_project_path, "content_for(:#{key})")
      [key, eex, offset]
    end)

    EEx.compile_module(
      %EEx{
        name: name,
        source: eex_source,
        frontmatter: frontmatter,
        content_fors: cfs_eex,
        template_project_path: template_project_path,
        offset: offset
      }
    )

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
    source = @file_impl.read!(template)

    [frontmatter, body] = Fermo.Compilers.EEx.extract_frontmatter(source)

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
end
