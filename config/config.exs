import Config

if config_env() == :test do
  config :logger, :default_handler, false
end
