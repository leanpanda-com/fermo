defmodule Fermo.Live.ChangeHandler do
  @moduledoc false

  use GenServer

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def init(state) do
    subscribe(%{})
  end

  def handle_info({:file_event, _pid, {path, _event}}, state) do
    IO.puts "File changed, path: #{path}"

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
end
