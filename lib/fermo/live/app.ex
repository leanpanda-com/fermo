defmodule Fermo.Live.App do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Application.ensure_all_started(:telemetry)
    Application.ensure_all_started(:cowboy)

    cowboy = {
      Plug.Cowboy,
      scheme: :http,
      plug: Fermo.Live.Server,
      options: [dispatch: dispatch(), port: 4001]
    }
    children = [
      cowboy,
      {Fermo.Live.Watcher, dirs: ["priv/source"]},
      {Fermo.Live.ChangeHandler, []},
      {Fermo.Live.Dependencies, []},
      {Fermo.Live.SocketRegistry, []}
    ]
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, pid}
  end

  def stop(state) do
    IO.puts "state: #{inspect(state, [pretty: true, width: 0])}"
    Application.stop(:cowboy)
    Application.stop(:telemetry)
  end

  defp dispatch() do
    [
      {
        :_,
        [
          {"/__fermo/ws/[...]", Fermo.Live.Socket, [name: :fermo_live_socket]},
          {:_, Plug.Cowboy.Handler, {Fermo.Live.Server, Fermo.Live.Server.init([])}}
        ]
      }
    ]
  end
end
