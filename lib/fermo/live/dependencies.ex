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
    config = Fermo.post_config(config)
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

  def handle_call({:page_from_path, path}, _from, config) do
    page = Enum.find(config.pages, &(&1.path == path))
    if page do
      IO.puts "Dependencies page_from_path page: #{inspect(page, [pretty: true, width: 0])}"
      {:reply, {:ok, page}, config}
    else
      {:reply, {:error, :not_found}, config}
    end
  end

  def handle_call({:pages_from_template, template}, _from, config) do
    pages = Enum.filter(config.pages, &(&1.template == template))
    {:reply, {:ok, pages}, config}
  end
end
