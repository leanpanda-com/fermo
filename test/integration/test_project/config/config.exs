use Mix.Config

config :slime, :keep_lines, true
config :yamerl, node_mods: []

config :fermo, :base_url, System.fetch_env!("BASE_URL")

environment_config = "#{Mix.env()}.exs"

if File.regular?(Path.join("config", environment_config)) do
  import_config environment_config
end
