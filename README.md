# LoggerTelegramBackend

[![Build Status](https://github.com/adriankumpf/logger-telegram-backend/workflows/CI/badge.svg)](https://github.com/adriankumpf/logger-telegram-backend/actions)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/logger_telegram_backend)
[![Hex.pm](https://img.shields.io/hexpm/v/logger_telegram_backend?color=%23714a94)](http://hex.pm/packages/logger_telegram_backend)

<!-- MDOC !-->

A logger backend for [Telegram](https://telegram.org/).

## Installation

Add `:logger_telegram_backend`, `:logger_backends` and `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_telegram_backend, "~> 3.0-rc"},
    {:logger_backends, "~> 1.0"},
    {:finch, "~> 1.18"},
  ]
end
```

In your `Application.start/2` callback, add the `LoggerTelegramBackend` backend:

```elixir
@impl true
def start(_type, _args) do
  LoggerBackends.add(LoggerTelegramBackend)

  # ...
end
```

## Configuration

First you need to create a [Telegram Bot](https://core.telegram.org/bots). Follow the [instructions here](https://core.telegram.org/bots#6-botfather) to create one and get the `token` for the bot. You will need to send a message first as bots are not allowed to contact users. Then retrieve your `chat_id` with `$ curl -X GET https://api.telegram.org/botYOUR_TOKEN/getUpdates`.

Then configure the telegram `chat_id` and bot `token`:

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "$chatId",
  token: "$botToken"
```

### Options

The available options are:

- `:level` - the level to be logged by this backend (either `:debug`, `:info`, `:warning` or `:error`).

  Note that messages are first filtered by the general `:level` configuration for the `:logger` application.

  Default: `nil` (all levels are logged)

- `:metadata` - the metadata to be included in the message. Setting `:metadata` to `:all` will get all metadata.
  Default: `[:line, :function, :module, :application, :file]`.

- `:metadata_filter` - the metadata which is required in order for a message to be logged.

  Default: `nil`

- `:client` - If you need different functionality for the HTTP client, you can define your own module that implements the `LoggerTelegramBackend.HTTPClient` behaviour and set `client` to that module.

  By default, selects the first client in the list whose application is loaded:

  - `LoggerTelegramBackend.HTTPClient.Finch` (requires `:finch`)
  - `LoggerTelegramBackend.HTTPClient.Hackney` (requires`:hackney`)

- `:client_pool_opts` - The options passed to configure the pool.

  See [Finch](https://hexdocs.pm/finch/Finch.html#start_link/1) or [Hackney](https://hexdocs.pm/hackney/).

  Default: `[]`

- `:client_request_opts` - The options passed on every request.

  See [Finch](https://hexdocs.pm/finch/Finch.html#request/3) or [Hackney](https://hexdocs.pm/hackney/).

  Default: `[]`

### Examples

#### Custom HTTP client

1. Add a module that implements the `LoggerTelegramBackend.HTTPClient` behaviour
2. Pass your client module to the `:client` option:

   ```elixir
   config :logger, LoggerTelegramBackend,
     client: MyClient,
     # ...
   ```

#### Metadata filter

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "$chatId",
  token: "$botToken",
  level: :info,
  metadata: :all,
  metadata_filter: [application: :ui]
```

#### SOCKS5 proxy

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "$chatId",
  token: "$botToken",
  client: LoggerTelegramBackend.HTTPClient.Hackney,
  client_request_opts: [
    proxy: {:socks5, ~c"127.0.0.1", 9050}
  ]
```

See the [hackney docs](https://github.com/benoitc/hackney#proxy-a-connection) for further information.
