import Config

env_config = "#{config_env()}.exs"
if File.regular?(Path.join("config", env_config)) do
  import_config env_config
end
