# TelegramLoggerBackend

A logger backend for posting messages to [Telegram]( https://telegram.org/).

## Installation

**Note: this package is still in beta and thus not yet available on hex**

Add `:telegram_logger_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:telegram_logger_backend, "~> 0.4"}]
end
```

## Configuration

Add `TelegramLoggerBackend` to the `:backends` configuration. Then add your
telegram `chat_id` and bot `token`:

```elixir
config :logger, backends: [TelegramLoggerBackend, :console]

config :logger, :telegram,
  chat_id: "$chatId",
  token: "$botToken"
```

The logger configuration is read at runtime from the application environment so
that you can provide it via
[distillerys](https://github.com/bitwalker/distillery) dynamic configuration
with environment variables.

### Options

In addition, the following options are available:

  * `:level` - the level to be logged by this backend (either `:debug`,
    `:info`, `:warn` or `:error`). Note that messages are filtered by the
    general `:level` configuration for the `:logger` application first. If not
    explicitly configured all levels are logged.
  * `:metadata` - the metadata to be included in the telegram message. Defaults
    to  `[:line, :function, :module, :application, :file]`. Setting `:metadata`
    to `:all` gets all metadata.
  * `:metadata_filter` - the metadata which is required in order for a message
    to be logged. Example: `metadata_filter: [application: :ui]`.


#### Example

```elixir
config :logger, :telegram,
  chat_id: "$chatId",
  token: "$botToken",
  level: :info,
  metadata: :all
  metadata_filter: [application: :ui]
```

### Multiple logger handlers

Like the
[LoggerFileBackend](https://github.com/onkel-dirtus/logger_file_backend)
multiple logger handlers may be configured, each with different `:chat_id`s,
`:level`s etc. Each handler has to be configured as a logger backend:

```elixir
config :logger,
  backends: [
    {TelegramLoggerBackend, :telegram_filter},
    {TelegramLoggerBackend, :telegram_level},
    :console
  ]

config :logger, :telegram_filter,
  chat_id: "$chatId",
  token: "$botToken",
  metadata_filter: [application: :ui],
  metadata: [:line, :function, :module, :pid]

config :logger, :telegram_level,
  chat_id: "$chatId",
  token: "$botToken",
  level: :warn,
```
