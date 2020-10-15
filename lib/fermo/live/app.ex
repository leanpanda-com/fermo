defmodule Fermo.Live.App do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Application.ensure_all_started(:telemetry)
    Application.ensure_all_started(:cowboy)
    children = [
      {Plug.Cowboy, scheme: :http, plug: Fermo.Live.Plug, options: [port: 4001]}
    ]
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
    counts = Supervisor.count_children(pid)
    IO.puts "counts: #{inspect(counts, [pretty: true, width: 0])}"
    {:ok, pid}
  end

  def stop(state) do
    IO.puts "state: #{inspect(state, [pretty: true, width: 0])}"
    Application.stop(:cowboy)
    Application.stop(:telemetry)
  end
end
