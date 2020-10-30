defmodule Fermo.Live.ChangeHandler do
  @moduledoc false

  use GenServer

  import Mix.Fermo.Paths, only: [app_path: 0]

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def init(_initial_state) do
    subscribe(%{})
  end

  def handle_info({:file_event, _pid, {path, event}}, state) do
    if :modified in event do
      IO.puts "File changed: '#{path}'"
      recompile()
      relative_path(path)
      |> notify_sockets()
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

  defp recompile() do
    :ok = Mix.Fermo.Compiler.run()
  end

  defp relative_path(path) do
    IO.puts "path: #{path}"
    root = Path.expand(Path.join(app_path(), "priv/source")) <> "/"
    IO.puts "root: #{root}"
    if String.starts_with?(path, root) do
      root_length = byte_size(root)
      <<_::binary-size(root_length), rest::binary>> = path
      rest
    else
      nil
    end
  end

  defp notify_sockets(relative_path) do
    IO.puts "relative_path: #{relative_path}"
    case Fermo.Live.Dependencies.page_from_template(relative_path) do
      {:ok, page} ->
        IO.puts "page: #{inspect(page, [pretty: true, width: 0])}"
        subscribed = Fermo.Live.SocketRegistry.subscribed(page.path)
        IO.puts "subscribed: #{inspect(subscribed, [pretty: true, width: 0])}"
        Enum.each(subscribed, fn pid ->
          send(pid, {:reload})
        end)
      _ ->
        IO.puts "notify_sockets page not found"
        :not_found
    end
  end
end
