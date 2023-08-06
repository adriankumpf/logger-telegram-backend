# LoggerTelegramBackend

[![Build Status](https://github.com/adriankumpf/logger-telegram-backend/workflows/CI/badge.svg)](https://github.com/adriankumpf/logger-telegram-backend/actions)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/logger_telegram_backend)
[![Hex.pm](https://img.shields.io/hexpm/v/logger_telegram_backend?color=%23714a94)](http://hex.pm/packages/logger_telegram_backend)

<!-- MDOC !-->

A logger backend for [Telegram](https://telegram.org/).

## Installation

Add `:logger_telegram_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_telegram_backend, "~> 3.0"},
    {:logger_backends, "~> 1.0"},
    {:hackney, "~> 1.18"},
  ]
end
```

In your `c:Application.start/2` callback, add the `LoggerTelegramBackend` backend:

```elixir
@impl true
def start(_type, _args) do
  LoggerBackends.add(LoggerTelegramBackend)

  # ...
end
```

## Configuration

First of all you need to create a [Telegram bot](https://core.telegram.org/bots). Follow the [instructions here](https://core.telegram.org/bots#6-botfather) to create one and get the `token` for the bot. Since bots are not allowed to contact users, you need to send a message first. Afterwards, retrieve your `chat_id` with `$ curl -X GET https://api.telegram.org/botYOUR_TOKEN/getUpdates`.

Then configure the telegram `chat_id` and bot `token`:

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "$chatId",
  token: "$botToken"
```

### Options

The following options are available:

- `:level` - the level to be logged by this backend (either `:debug`, `:info`, `:warning` or `:error`).

  Note that messages are filtered by the general `:level` configuration for the `:logger` application first.

  Default: `nil` (all levels are logged)

- `:metadata` - the metadata to be included in the telegram message. Setting `:metadata` to `:all` gets all metadata.

  Default: `[:line, :function, :module, :application, :file]`.

- `:metadata_filter` - the metadata which is required in order for a message to be logged.

  Default: `nil`

- `:client` - If you need different functionality for the HTTP client, you can define your own module that implements the `LoggerTelegramBackend.HTTPClient` behaviour and set `client` to that module

  Default: `LoggerTelegramBackend.HackneyClient`

- `:hackney_opts`

  Default: `[pool: :logger_telegram_backend_pool]`

- `:hackney_pool_max_connections`

  Default: `50`

- `:hackney_pool_timeout`

  Default: `5000`

### Examples

#### Finch client

1. Add Finch instead of `:hackney` to your list of dependencies:

   ```elixir
    {:finch, "~> 0.16"}
   ```

2. Add a module that implements the `LoggerTelegramBackend.HTTPClient` behaviour:

   ```elixir
   defmodule MyFinchClient do
     @behaviour LoggerTelegramBackend.HTTPClient

     @finch_pool_name MyApp.Finch

     @impl true
     def child_spec do
       Finch.child_spec(name: @finch_pool_name)
     end

     @impl true
     def request(method, url, headers, body) do
       req = Finch.build(method, url, headers, body)

       case Finch.request(req, @finch_pool_name) do
         {:ok, %Finch.Response{status: status, headers: headers, body: body}} ->
           {:ok, status, headers, body}

         {:error, reason} ->
           {:error, reason}
       end
     end
   end
   ```

3. Pass your client module to the `:client` option:

   ```elixir
   config :logger, LoggerTelegramBackend,
     client: MyFinchClient,
     # ...
   ```

#### Metadata filter

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "$chatId",
  token: "$botToken",
  level: :info,
  metadata: :all
  metadata_filter: [application: :ui]
```

#### SOCKS5 proxy

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "$chatId",
  token: "$botToken",
  hackney_opts: [
    ssl: [verify: :verify_none],
    hackney: [insecure: true],
    proxy: {:socks5, ~c"127.0.0.1", 9050}
  ]
```

See the [hackney docs](https://github.com/benoitc/hackney#proxy-a-connection) for further information.
