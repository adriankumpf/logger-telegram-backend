# TelegramLoggerBackend

A logger backend for posting messages to [Telegram]( https://telegram.org/).

## Installation

**Note: this package is still in beta and thus not yet available on hex**

Add `:telegram_logger_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:telegram_logger_backend, "~> 0.2.0"}]
end
```

Then add `TelegramLoggerBackend` to the `:backends` configuration and add the
telegram credentials:

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

  * `:level` - the level to be logged by this backend (either `:debug`,
    `:info`, `:warn` or `:error`). Note that messages are filtered by the
    general `:level` configuration for the `:logger` application first. If not
    explicitly configured all levels are logged.
  * `:metadata` - the metadata to be included in the telegram message. Defaults
    to  `[:line, :function, :module, :application, :file]`. Setting `:metadata`
    to `:all` prints all metadata.
  * `:metadata_filter` - the metadata which is required in order for a message
    to be logged. Example: `metadata_filter: [application: :ui]`.


#### Example

```elixir
config :logger, :telegram,
  chat_id: "$chatId",
  token: "$botToken",
  level: :info,
  metadata: :all
  metadata_filter: [application: ui]
```
