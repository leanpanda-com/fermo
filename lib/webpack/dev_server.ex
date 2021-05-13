defmodule Webpack.DevServer do
  use GenServer

  @moduledoc """
  Runs the Webpack Development server for live mode.
  """

  @webpack_config_path "webpack.config.js"

  def start_link(_opts) do
    if File.exists?(@webpack_config_path) do
      {:ok, _pid} = GenServer.start_link(__MODULE__, %{}, name: :webpack_dev_server)
    else
      {:error, :webpack_config_not_found}
    end
  end

  def init(_args) do
    IO.puts "Starting Webpack dev server..."
    port = Port.open(
      {:spawn, "yarn run webpack serve"},
      [{:env, [{'NODE_ENV', 'development'}]}]
    )

    {:ok, port}
  end

  def handle_info({_port, {:data, charlist}}, state) do
    message = List.to_string(charlist)
    if String.match?(message, ~r/manifest.json\s.*?\[emitted\]/) do
      IO.puts "manifest emitted!"
      {:ok} = Webpack.Assets.load_manifest()
    end
    {:noreply, state}
  end
  def handle_info(other, state) do
    IO.puts "Webpack.DevServer message: #{inspect(other, [pretty: true, width: 0])}"
    {:noreply, state}
  end
end
