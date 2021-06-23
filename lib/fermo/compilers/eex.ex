defmodule Fermo.Compilers.EEx do
  import Mix.Fermo.Paths
  import Fermo.Naming

  defstruct [
    :name,
    :source,
    :frontmatter,
    :content_fors,
    :template_project_path,
    :offset
  ]

  @file_impl Application.get_env(:fermo, :file_impl, File)

  def compile(template_project_path) do
    template_source_path = absolute_to_source(template_project_path)
    name = source_path_to_module(template_source_path)
    source = File.read!(template_project_path)
    [frontmatter, body] = extract_frontmatter(source)

    compile_module(
      %__MODULE__{
        name: name,
        source: body,
        frontmatter: frontmatter,
        content_fors: [],
        template_project_path: template_project_path,
        offset: 0
      }
    )
  end

  def extract_frontmatter(source = "---\n" <> _rest) do
    [_, frontmatter_yaml, body] = String.split(source, "---\n")
    frontmatter = YamlElixir.read_from_string(frontmatter_yaml)
    [frontmatter, body]
  end
  def extract_frontmatter(body) do
    [%{}, body]
  end

  def compile_module(%__MODULE__{} = module) do
    # We do a first compilation here so we can trap errors
    # and give a better message
    try do
      EEx.compile_string(module.source, line: module.offset, file: module.template_project_path)
    rescue
      e in TokenMissingError ->
        message = """
        Template compilation error: #{e.description}
        Path: '#{module.template_project_path}'
        """
        raise Fermo.Error, message: message
    end

    quoted_module = quote(
      bind_quoted: [
        content_fors: module.content_fors,
        frontmatter: Macro.escape(module.frontmatter, unquote: true),
        name: module.name,
        offset: module.offset,
        source: module.source,
        template_path: module.template_project_path
      ],
      file: module.template_project_path
    ) do
      compiled = EEx.compile_string(source, line: offset, file: template_path)

      cfs_compiled = Enum.map(content_fors, fn [key, eex, offset] ->
        cf_compiled = EEx.compile_string(eex, line: offset, file: template_path)
        {key, cf_compiled}
      end)

      defmodule :"#{name}" do
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
          unquote(template_path)
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
    [{module_name, bytecode} | _other] = Code.compile_quoted(quoted_module)
    Code.compiler_options(ignore_module_conflict: false)
    base = Mix.Project.compile_path()
    module_path = Path.join(base, "#{module_name}.beam")
    @file_impl.write!(module_path, bytecode, [:write])
  end
end
