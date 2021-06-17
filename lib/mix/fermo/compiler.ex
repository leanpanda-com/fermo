defmodule Mix.Fermo.Compiler do
  @moduledoc false

  require Logger

  import Mix.Fermo.Paths

  @file_impl Application.get_env(:fermo, :file_impl, File)
  @compiler Application.get_env(:fermo, :compiler, Fermo.Compiler)
  @mix_compiler_manifest Application.get_env(:fermo, :mix_compiler_manifest, Mix.Fermo.Compiler.Manifest)
  @mix_utils Application.get_env(:fermo, :mix_utils, Mix.Utils)

  def run do
    :yamerl_app.set_param(:node_mods, [])
    compilation_timestamp = compilation_timestamp()
    ensure_helpers_module()

    all_sources = all_sources()
    timestamp = @mix_compiler_manifest.timestamp()
    helpers_changed = helpers_changed?(timestamp)
    changed = if helpers_changed do
      MapSet.to_list(all_sources)
    else
      changed_since(all_sources, timestamp)
    end

    count = length(changed)
    if count > 0 do
      Logger.info "Fermo.Compiler compiling #{count} file(s)... "
      Enum.each(changed, fn template_project_path ->
        Logger.info "Compiling #{template_project_path}"
        @compiler.compile(template_project_path)
      end)
      Logger.info "Done!"
    end

    {:ok} = @mix_compiler_manifest.write(all_sources, compilation_timestamp)

    :ok
  end

  defp changed_since(paths, timestamp) do
    Enum.filter(paths, &(@mix_utils.last_modified(&1) > timestamp))
  end

  defp all_sources do
    @mix_utils.extract_files([full_source_path()], [:slim])
    |> MapSet.new()
  end

  def compilation_timestamp, do: System.os_time(:second)

  def helpers_module, do: :"Elixir.Helpers"

  def helpers_path, do: "lib/helpers.ex"

  def ensure_helpers_module do
    Code.ensure_loaded(helpers_module())
    has_helpers = has_helpers?()
    if !has_helpers do
      [{module, bytecode}] = Code.compile_string("defmodule #{helpers_module()} do; defmacro __using__(_opts \\\\ %{}) do; end; end")
      base = Mix.Project.compile_path()
      module_path = Path.join(base, "#{module}.beam")
      @file_impl.write!(module_path, bytecode, [:write])
      Code.ensure_loaded(helpers_module())
    end
  end

  def has_helpers? do
    function_exported?(helpers_module(), :__info__, 1)
  end

  def helpers_changed?(timestamp) do
    @mix_utils.last_modified(helpers_path()) > timestamp
  end
end
