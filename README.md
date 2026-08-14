# LoggerTelegramBackend

[![Build Status](https://github.com/adriankumpf/logger-telegram-backend/workflows/CI/badge.svg)](https://github.com/adriankumpf/logger-telegram-backend/actions)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/logger_telegram_backend)
[![Hex.pm](https://img.shields.io/hexpm/v/logger_telegram_backend?color=%23714a94)](http://hex.pm/packages/logger_telegram_backend)

<!-- MDOC -->

A logger backend for [Telegram](https://telegram.org/).

Intended for low-volume notifications: a handful of alerts to a chat, not log shipping. See [Caveats](#caveats) before reaching for it.

## Installation

Add `:logger_telegram_backend` and `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_telegram_backend, "~> 4.0"},
    {:finch, "~> 0.22"},
  ]
end
```

### Add the backend

In your `Application.start/2` callback, add the `LoggerTelegramBackend`:

```elixir
@impl true
def start(_type, _args) do
  {:ok, _pid} = LoggerTelegramBackend.attach()

  # ...
end
```

Add the following to your configuration:

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "your_chat_id",
  token: "your_bot_token"
```

### Configure the Telegram bot

To create a Telegram bot, follow the instructions [here](https://core.telegram.org/bots/features#creating-a-new-bot) and get the `token` for the bot.

Then send a message to the bot and get your `chat_id`:

```bash
TOKEN="your_bot_token"
curl https://api.telegram.org/bot$TOKEN/getUpdates
```

## Caveats

Messages are sent synchronously from the `Logger` event manager, so a slow or unreachable Telegram API blocks the process that called `Logger.error/1`. Once Logger's `:sync_threshold` is crossed the stall spreads to every process that logs, and once `:discard_threshold` is crossed events are dropped for _all_ backends attached to the event manager, not just this one. Telegram also rate limits to roughly one message per second per chat, and nothing here queues, retries or rate limits.

Keep `:level` at `:warning` or `:error`, narrow further with `:metadata_filter`, and set a timeout via `:client_request_opts`, since Finch defaults `:request_timeout` to `:infinity` on HTTP/1. For high-throughput or delivery-critical logging, use a dedicated log aggregator.

## Configuration

All options live under the `LoggerTelegramBackend` key of the `:logger` application. Since the token and chat id are secrets, read them at runtime from `config/runtime.exs`:

```elixir
# config/runtime.exs
config :logger, LoggerTelegramBackend,
  chat_id: System.fetch_env!("TELEGRAM_CHAT_ID"),
  token: System.fetch_env!("TELEGRAM_TOKEN"),
  level: :warning
```

| Option                 | Description                                                                                             | Default                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `:token`               | Bot token. Required.                                                                                    |                                                    |
| `:chat_id`             | Chat to send messages to. Required.                                                                     |                                                    |
| `:level`               | Lowest level this backend sends. Events are filtered by the `:logger` application's own `:level` first. | `nil` (everything)                                 |
| `:metadata`            | Metadata keys to include, or `:all` for everything.                                                     | `[:line, :function, :module, :application, :file]` |
| `:metadata_filter`     | Key-value pairs or bare keys that must be present for a message to be sent.                             | `[]`                                               |
| `:client`              | Module implementing the `LoggerTelegramBackend.HTTPClient` behaviour.                                   | `LoggerTelegramBackend.HTTPClient.Finch`           |
| `:client_pool_opts`    | Options for the HTTP client pool. See [`Finch.start_link/1`](https://hexdocs.pm/finch/Finch.html#start_link/1). | `[]`                                        |
| `:client_request_opts` | Options passed to each request. See [`Finch.request/3`](https://hexdocs.pm/finch/Finch.html#request/3). | `[]`                                               |

Invalid or missing options are reported as a `LoggerTelegramBackend.ConfigError` when the backend is attached. Options can also be changed at runtime with `LoggerTelegramBackend.configure/1`.

### Filtering messages

`:metadata_filter` restricts which messages are sent. Every entry must match:

```elixir
# metadata must contain application: :core
config :logger, LoggerTelegramBackend, metadata_filter: [application: :core]

# metadata must contain the key :user, set to any value
config :logger, LoggerTelegramBackend, metadata_filter: [:user]

# metadata must contain application: :core AND the key :user
config :logger, LoggerTelegramBackend, metadata_filter: [{:application, :core}, :user]
```

### Using a proxy

An HTTP proxy is configured through `:client_pool_opts`:

```elixir
config :logger, LoggerTelegramBackend,
  client_pool_opts: [conn_opts: [proxy: {:http, "127.0.0.1", 8888, []}]]
```

See Finch's [pool configuration options](https://hexdocs.pm/finch/Finch.html#start_link/1-pool-configuration-options) for the rest.

### Using a different HTTP client

Finch is the default but not a requirement. Implement the `LoggerTelegramBackend.HTTPClient` behaviour and point `:client` at it to use something else, in which case `:finch` can be dropped from your dependencies. See `LoggerTelegramBackend.HTTPClient` for an example built on `:hackney`.

<!-- MDOC -->

## License

This project is Licensed under the [MIT License](LICENSE).
