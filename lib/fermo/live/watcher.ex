defmodule Fermo.Live.Watcher do
  @moduledoc false
  @monitor_name :fermo_live_reload_file_monitor

  use GenServer
  require Logger

  def init(_opts) do
    {:ok, %{}}
  end

  def start_link(opts) do
    opts = [
      name: @monitor_name,
      dirs: opts[:dirs]
    ]

    case FileSystem.start_link(opts) do
      {:ok, pid} ->
        {:ok, pid}

      other ->
        Logger.warn """
        Failed to start file watcher for live reload
        """
        other
    end
  end

  def monitor_name do
    @monitor_name
  end
end
