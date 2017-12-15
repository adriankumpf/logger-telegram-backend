# TelegramLoggerBackend

A logger backend for posting messages to [Telegram]( https://telegram.org/).

## Installation

Add `:telegram_logger_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:telegram_logger_backend, "~> 0.1.0"}]
end
```

Then add `TelegramLoggerBackend` to the `:backends` configuration and set the
`:level` to be logged as well as the telegram related configuration:

```elixir
config :logger, backends: [TelegramLoggerBackend, :console]

config :logger, :telegram,
  level: :warn,
  chat_id: 1111111,
  token: "yourBotToken"
```

### Options

  * `:level` - the level to be logged by this backend (either `:debug`,
    `:info`, `:warn` or `:error`). Note that messages are filtered by the
    general `:level` configuration for the `:logger` application first.
  * `:metadata` - the metadata to be included in the telegram message. Defaults
    to some of the extra keys of the `:metadata` list: `[:line, :function,
    :module, :application, :file]`. Setting `:metadata` to `:all` prints all
    metadata.
