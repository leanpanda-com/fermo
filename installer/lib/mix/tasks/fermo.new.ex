defmodule Mix.Tasks.Fermo.New do
  @moduledoc """
  Creates a new Fermo project.

  It expects the **path** of the project as an argument.

      mix fermo.new PATH

  The application name and module name will be derived
  from the path.

  ## Examples

      mix fermo.new hello_world
  """

  use Mix.Task
  alias Fermo.New.Project
  use Fermo.New.Generator

  @version Mix.Project.config()[:version]
  @shortdoc "Creates a new Fermo v#{@version} project"

  @templates [
    "config/config.exs",
    "config/dev.exs",
    ".envrc",
    ".envrc.private",
    ".gitignore",
    "lib/helpers.ex",
    "lib/<%= project[:app] %>.ex",
    "mix.exs",
    "package.json",
    "priv/source/javascripts/application.js",
    "priv/source/layouts/layout.html.slim",
    "priv/source/stylesheets/application.sass",
    "priv/source/templates/home.html.slim",
    "webpack.config.js"
  ]

  @other_deps """
    ,
    {:datocms_graphql_client, "~> 0.14.3"},
    {:fermo_datocms_graphql_client, "~> 0.14.3"}
  """

  @impl true
  def run(argv) do
    case OptionParser.parse(argv, strict: []) do
      {_opts, []} ->
        Mix.Tasks.Help.run(["fermo.new"])

      {[], [base_path], []} ->
        generate(base_path)
    end
  end

  defp generate(base_path) do
    with {:ok} <- check_name(base_path),
         {:ok, %Project{} = project} <- new_project(base_path),
         {:ok} <- ensure_directory(project),
         {:ok} <- generate_files(project) do
      Mix.shell().info("""
        Project created!

        Now:
          cd #{base_path}
          mix deps.get
          mix compile
          yarn
          mix fermo.live

        You'll need to create a DatoCMS site and set it's API key in .envrc
      """)
    else
      {:error, :bad_name, error} ->
        Mix.raise error
      {:error, :directory_not_empty} ->
        Mix.raise "The directory #{base_path} is not empty"
    end
  end

  defp check_name(name) do
    if name =~ Regex.recompile!(~r/^[a-z][\w_]*$/) do
      {:ok}
    else
      {:error, :bad_name, "The app name '#{name}' is incorrect. The name must start with a lower-case letter and contain only alphanumeric characters and underscores"}
    end
  end

  defp new_project(path) do
    project = %Project{
      app: String.to_atom(path),
      module: Macro.camelize(path),
      path: path
    }
    {:ok, project}
  end

  defp ensure_directory(%Project{path: path}) do
    case File.ls(path) do
      {:error, :enoent} ->
        File.mkdir_p(path)
        {:ok}
      [] ->
        {:ok}
      _ ->
        {:error, :directory_not_empty}
    end
  end

  defp generate_files(%Project{} = project) do
    config = Mix.Project.config()
    context = [
      project: Map.from_struct(project),
      config: Enum.into(config, %{}),
      mix: %{other_deps: @other_deps}
    ]

    Enum.each(@templates, fn template ->
      {:ok} = generate_file(template, context)
    end)

    {:ok}
  end

  defp generate_file(template, context) do
    content = render(template, context)

    path = EEx.eval_string(template, context)
    output_pathname = Path.join(context[:project].path, path)

    create_directory(Path.dirname(output_pathname))
    create_file(output_pathname, content)

    {:ok}
  end
end
