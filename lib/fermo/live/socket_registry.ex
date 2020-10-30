defmodule Fermo.Live.SocketRegistry do
  use GenServer

  @name :fermo_registry

  def init(_opts) do
    {:ok, %{}}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def subscribe(path, pid) when is_pid(pid) do
    GenServer.call(@name, {:subscribe, path, pid})
  end

  def unsubscribe(pid) do
    GenServer.call(@name, {:unsubscribe, pid})
  end

  def subscribed(path) do
    GenServer.call(@name, {:subscribed, path})
  end

  def handle_call({:subscribe, path, pid}, _from, registry) do
    subscribed = [pid | registry[path] || []]
    Process.monitor(pid)
    registry = Map.put(registry, path, subscribed)
    {:reply, :ok, registry}
  end

  def handle_call({:unsubscribe, pid}, _from, registry) do
    {:reply, :unsubscribed, unsubscribe_pid(registry, pid)}
  end

  def handle_call({:subscribed, path}, _from, registry) do
    {:reply, Map.get(registry, path, []), registry}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, registry) do
    IO.puts "Process down"
    {:noreply, unsubscribe_pid(registry, pid)}
  end
  def handle_info(_info, registry), do: {:noreply, registry}

  defp unsubscribe_pid(registry, pid) do
    Enum.reduce(registry, %{}, fn {path, pids}, acc ->
      other = Enum.filter(pids, &(&1 != pid))
      Map.put(acc, path, other)
    end)
  end
end
