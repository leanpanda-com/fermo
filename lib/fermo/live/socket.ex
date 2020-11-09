defmodule Fermo.Live.Socket do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    {:cowboy_websocket, request, []}
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_info({:reload}, state) do
    {:reply, {:text, "reload"}, state}
  end
  def websocket_info(_info, state) do
    {:ok, state}
  end

  def websocket_handle({:text, "subscribe:live-reload:" <> path}, state) do
    Fermo.Live.SocketRegistry.subscribe(path, self())

    {:reply, {:text, "fermo:live-reload subscribed for '#{path}'"}, state}
  end
  def websocket_handle(_info, state) do
    {:ok, state}
  end
end
