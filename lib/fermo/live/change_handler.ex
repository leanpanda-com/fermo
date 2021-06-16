defmodule Fermo.Live.ChangeHandler do
  @moduledoc false

  use GenServer

  import Mix.Fermo.Paths, only: [app_relative_path: 1]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def init(_initial_state) do
    subscribe(%{})
  end

  def handle_info({:file_event, _pid, {path, event}}, state) do
    if :modified in event do
      app_relative_path = app_relative_path(path)
      library = library?(app_relative_path)
      if library do
        Mix.Tasks.Compile.Elixir.run([])
        recompile_templates()
        notify_lib_change()
      else
        recompile_templates()
        template_relative_path(app_relative_path)
        |> notify_template_change()
      end
    end

    {:noreply, state}
  end

  defp subscribe(_state) do
    monitor_name = Fermo.Live.Watcher.monitor_name()
    if Process.whereis(monitor_name) do
      FileSystem.subscribe(monitor_name)
      {:ok, self()}
    else
      {:error, %{message: "live reload backend not running"}}
    end
  end

  defp recompile_templates() do
    :ok = Mix.Fermo.Compiler.run()
  end

  defp library?(path) do
    String.starts_with?(path, "lib/")
  end

  defp template_relative_path(path) do
    root = "priv/source/"
    if String.starts_with?(path, root) do
      root_length = byte_size(root)
      <<_::binary-size(root_length), rest::binary>> = path
      rest
    else
      nil
    end
  end

  defp notify_template_change(template_relative_path) do
    {:ok, pages} = Fermo.Live.Dependencies.pages_by_dependency(
      :template,
      template_relative_path
    )
    Enum.each(pages, fn page ->
      {:ok} = Fermo.Live.SocketRegistry.reload(page.path)
    end)
  end

  defp notify_lib_change() do
    {:ok} = Fermo.Live.SocketRegistry.reload_all()
  end
end
