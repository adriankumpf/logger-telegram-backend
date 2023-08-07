import Config

if Mix.env() == :test do
  config :logger, :default_handler, false
end
