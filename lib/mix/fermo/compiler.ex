defmodule Mix.Fermo.Compiler do
  import Fermo.Naming
  import Mix.Fermo.Paths
  alias Mix.Fermo.Compiler.Manifest

  def run do
    :yamerl_app.set_param(:node_mods, [])
    compilation_timestamp = compilation_timestamp()
    ensure_helpers_module()
    all_sources = all_sources()
    changed = changed_since(all_sources, Manifest.timestamp())
    count = length(changed)
    if count > 0 do
      IO.write "Fermo.Compiler compiling #{count} file(s)... "
      Enum.each(changed, &compile_file/1)
      IO.puts "Done!"
    end

    {:ok} = Manifest.write(all_sources, compilation_timestamp)

    :ok
  end

  defp compile_file(template) do
    module =
      template
      |> absolute_to_source()
      |> source_path_to_module()

    {frontmatter, content_fors, offset, body} = parse_template(template)

    eex_source = precompile_slim(body, template)

    # We do a first compilation here so we can trap errors
    # and give a better message
    try do
      EEx.compile_string(eex_source, line: offset, file: template)
    rescue
      e in TokenMissingError ->
        message = """
        Template compilation error: #{e.description}
        Path: '#{template}'
        """
        raise Fermo.Error, message: message
    end

    cfs_eex = Enum.map(content_fors, fn [key, block, offset] ->
      eex = precompile_slim(block, template, "content_for(:#{key})")
      [key, eex, offset]
    end)

    quoted_module = quote bind_quoted: binding(), file: template do
      compiled = EEx.compile_string(eex_source, line: offset, file: template)

      cfs_compiled = Enum.map(cfs_eex, fn [key, eex, offset] ->
        cf_compiled = EEx.compile_string(eex, line: offset, file: template)
        {key, cf_compiled}
      end)

      defmodule :"#{module}" do
        use Helpers
        require Fermo.Partial
        import Fermo.Partial
        require Fermo.YieldContent
        import Fermo.YieldContent
        import FermoHelpers.Assets
        import FermoHelpers.DateTime
        import FermoHelpers.I18n
        import FermoHelpers.Links
        import FermoHelpers.String
        import FermoHelpers.Text

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

  defp changed_since(paths, timestamp) do
    Enum.filter(paths, &(Mix.Utils.last_modified(&1) > timestamp))
  end

  defp all_sources do
    Mix.Utils.extract_files([full_source_path()], [:slim])
    |> MapSet.new()
  end

  def compilation_timestamp, do: System.os_time(:second)

  def helpers_module, do: :"Elixir.Helpers"

  def ensure_helpers_module do
    Code.ensure_loaded(helpers_module())
    has_helpers = has_helpers?()
    if !has_helpers do
      [{module, bytecode}] = Code.compile_string("defmodule #{helpers_module()} do; defmacro __using__(_opts \\\\ %{}) do; end; end")
      base = Mix.Project.compile_path()
      module_path = Path.join(base, "#{module}.beam")
      File.write!(module_path, bytecode, [:write])
      Code.ensure_loaded(helpers_module())
    end
  end

  def has_helpers? do
    function_exported?(helpers_module(), :__info__, 1)
  end
end
