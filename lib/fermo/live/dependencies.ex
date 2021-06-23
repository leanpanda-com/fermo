defmodule Fermo.Live.Dependencies do
  use GenServer

  require Logger

  @name :fermo_dependencies

  @config Application.get_env(:fermo, :config, Fermo.Config)
  @i18n Application.get_env(:fermo, :i18n, Fermo.I18n)

  def init(app_module: app_module) do
    {:ok} = @i18n.load()
    config = load_config(app_module)
    {:ok, %{config: config, app_module: app_module}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def reinitialize() do
    {:ok} = GenServer.call(@name, {:reinitialize})
  end

  def page_from_path(path) do
    GenServer.call(@name, {:page_from_path, path})
  end

  def pages_by_dependency(type, value) do
    GenServer.call(@name, {:pages_by_dependency, type, value})
  end

  def start_page(path) do
    GenServer.call(@name, {:start_page, path})
  end

  def add_page_dependency(path, type, value) do
    GenServer.call(@name, {:add_page_dependency, path, type, value})
  end

  def handle_call({:reinitialize}, _from, %{app_module: app_module} = state) do
    config = load_config(app_module)
    {:reply, {:ok}, Map.put(state, :config, config)}
  end

  def handle_call({:page_from_path, path}, _from, state) do
    page = Enum.find(state.config.pages, &(&1.path == path))
    if page do
      {:reply, {:ok, page}, state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:pages_by_dependency, type, value}, _from, state) do
    pages = Enum.filter(state.config.pages, fn page ->
      dependencies = page.dependencies[type] || []
      Enum.member?(dependencies, value)
    end)
    {:reply, {:ok, pages}, state}
  end

  def handle_call({:start_page, path}, _from, state) do
    state = state
    |> update_page(path, &(reset_page_dependencies(&1)))

    {:reply, {:ok}, state}
  end

  def handle_call({:add_page_dependency, path, type, value}, _from, state) do
    state = update_page(state, path, fn page ->
      dependencies = page.dependencies[type] || []
      dependencies = if Enum.member?(dependencies, value) do
        dependencies
      else
        [value | dependencies]
      end
      put_in(page, [:dependencies, type], dependencies)
    end)

    {:reply, {:ok}, state}
  end

  defp load_config(app_module) do
    Logger.info "Requesting #{app_module}.config... "
    {:ok, config} = app_module.config()
    Logger.info "Done!"
    Logger.info "Running post config... "
    config =
      config
      |> @config.post_config()
      |> set_live_attributes()
    Logger.info "Done!"
    config
  end

  defp set_live_attributes(config) do
    fermo_live = Application.get_env(:fermo, :live, [])
    pages_live = Keyword.get(fermo_live, :pages, true)
    pages = Enum.map(config.pages, fn page ->
      page
      |> Map.put(:live, pages_live)
      |> reset_page_dependencies()
    end)

    config
    |> put_in([:pages], pages)
  end

  defp reset_page_dependencies(page) do
    template =
      case page.template do
        "/" <> rest -> rest
        path -> path
      end
    Map.put(page, :dependencies, %{template: [template]})
  end

  defp update_page(state, path, callback) do
    pages = Enum.map(state.config.pages, fn page ->
      if page.path == path do
        callback.(page)
      else
        page
      end
    end)

    put_in(state, [:config, :pages], pages)
  end
end
