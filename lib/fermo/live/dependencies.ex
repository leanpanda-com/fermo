defmodule Fermo.Live.Dependencies do
  use GenServer

  @name :fermo_dependencies

  def init(_opts) do
    {:ok} = FermoHelpers.load_i18n()
    module = Mix.Fermo.Module.module!()
    IO.write "Requesting #{module} config... "
    {:ok, config} = module.config()
    IO.puts "Done!"
    IO.write "Running post config... "
    config =
      config
      |> Fermo.post_config()
      |> set_live_attributes()
    IO.puts "Done!"
    {:ok, config}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def page_from_path(path) do
    GenServer.call(@name, {:page_from_path, path})
  end

  def pages_from_template(template) do
    IO.puts "Dependencies.pages_from_template template: #{inspect(template, [pretty: true, width: 0])}"
    GenServer.call(@name, {:pages_from_template, template})
  end

  def clear_transient_dependencies(path) do
    GenServer.call(@name, {:clear_transient_dependencies, path})
  end

  def add_page_dependency(path, template_source_path) do
    GenServer.call(@name, {:add_page_dependency, path, template_source_path})
  end

  def handle_call({:page_from_path, path}, _from, config) do
    page = Enum.find(config.pages, &(&1.path == path))
    if page do
      {:reply, {:ok, page}, config}
    else
      {:reply, {:error, :not_found}, config}
    end
  end

  def handle_call({:pages_from_template, template_source_path}, _from, config) do
    pages = Enum.filter(config.pages, fn page ->
      if page.template == template_source_path do
        true
      else
        # Doesn't match template, check in sub-dependencies (partials)
        Enum.find(page.transient, &(&1 == template_source_path))
      end
    end)
    {:reply, {:ok, pages}, config}
  end

  def handle_call({:clear_transient_dependencies, path}, _from, config) do
    config = update_page(config, path, fn page ->
      Map.put(page, :transient, [])
    end)
    {:reply, {:ok}, config}
  end

  def handle_call({:add_page_dependency, path, template_source_path}, _from, config) do
    config = update_page(config, path, fn page ->
      transient = page.transient
      transient = if Enum.find(transient, &(&1 == template_source_path)) do
        transient
      else
        [template_source_path | transient]
      end
      Map.put(page, :transient, transient)
    end)

    {:reply, {:ok}, config}
  end

  defp set_live_attributes(config) do
    pages = Enum.map(config.pages, fn page ->
      page
      |> Map.put(:live, true)
      |> Map.put(:transient, [])
    end)

    config
    |> put_in([:pages], pages)
  end

  defp update_page(config, path, callback) do
    pages = Enum.map(config.pages, fn page ->
      if page.path == path do
        callback.(page)
      else
        page
      end
    end)

    Map.put(config, :pages, pages)
  end
end
