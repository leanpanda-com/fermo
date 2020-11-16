defmodule Fermo.Live.App do
  @moduledoc false

  use Application

  alias Fermo.Live.{
    ChangeHandler,
    Dependencies,
    Server,
    Socket,
    SocketRegistry,
    Watcher
  }

  def start(_type, _args) do
    Application.ensure_all_started(:telemetry)
    Application.ensure_all_started(:cowboy)

    port = String.to_integer(System.get_env("PORT") || "4001")

    cowboy = {
      Plug.Cowboy,
      scheme: :http,
      plug: Server,
      options: [dispatch: dispatch(), port: port]
    }

    children = app_live_mode_servers() ++ [
      cowboy,
      {Watcher, dirs: ["priv/source"]},
      {ChangeHandler, []},
      {Dependencies, []},
      {SocketRegistry, []},
      {Webpack.DevServer, []}
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
          {"/__fermo/ws/[...]", Socket, [name: :fermo_live_socket]},
          {:_, Plug.Cowboy.Handler, {Server, Server.init([])}}
        ]
      }
    ]
  end

  # Allow projects to add children
  defp app_live_mode_servers() do
    case Application.fetch_env(:fermo, :live_mode_servers) do
      :error -> []
      {:ok, servers} -> servers
    end
  end
end
