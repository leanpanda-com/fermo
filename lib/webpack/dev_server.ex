defmodule Webpack.DevServer do
  use GenServer

  @moduledoc """
  Runs the Webpack Development server for live mode.
  """

  @webpack_config_path "webpack.config.js"

  def init(args) do
    {:ok, args}
  end

  def start_link(_opts) do
    if File.exists?(@webpack_config_path) do
      {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: :webpack_dev_server)
      System.cmd("yarn", ["run", "webpack-dev-server"], env: [{"NODE_ENV", "development"}])
      {:ok, pid}
    else
      {:error, :webpack_config_not_found}
    end
  end
end
