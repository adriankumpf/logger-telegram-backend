# LoggerTelegramBackend

[![Build Status](https://github.com/adriankumpf/logger-telegram-backend/workflows/CI/badge.svg)](https://github.com/adriankumpf/logger-telegram-backend/actions)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/logger_telegram_backend)
[![Hex.pm](https://img.shields.io/hexpm/v/logger_telegram_backend?color=%23714a94)](http://hex.pm/packages/logger_telegram_backend)

<!-- MDOC !-->

A logger backend for [Telegram](https://telegram.org/).

## Installation

Add `:logger_telegram_backend` and `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_telegram_backend, "~> 3.0-rc"},
    {:finch, "~> 0.16"},
  ]
end
```

In your `Application.start/2` callback, add the `LoggerTelegramBackend` backend:

```elixir
@impl true
def start(_type, _args) do
  LoggerTelegramBackend)

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

  Default: `LoggerTelegramBackend.HTTPClient.Finch` (requires `:finch`)

- `:client_pool_opts` - The options passed to configure the pool.

  See [Finch.start_link/1](https://hexdocs.pm/finch/Finch.html#start_link/1).

  Default: `[]`

- `:client_request_opts` - The options passed on every request.

  See [Finch.request/3](https://hexdocs.pm/finch/Finch.html#request/3).

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

##### Hackney Client

A client based on `:hackney` could look like this:

```elixir
defmodule HackneyClient do
  @behaviour LoggerTelegramBackend.HTTPClient

  @hackney_pool_name :logger_telegram_backend_pool

  @impl true
  def child_spec(opts) do
    :hackney_pool.child_spec(@hackney_pool_name, opts)
  end

  @impl true
  def request(method, url, headers, body, opts) do
    opts = Keyword.merge(opts, pool: @hackney_pool_name) ++ [:with_body]

    case :hackney.request(method, url, headers, body, opts) do
      {:ok, _status, _headers, _body} = result -> result
      {:error, _reason} = error -> error
    end
  end
end
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

#### HTTP proxy

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "$chatId",
  token: "$botToken",
  client_pool_opts: [conn_opts: [{:http, "127.0.0.1", 8888, []}]]
```

See the [Pool Configuration Options](https://hexdocs.pm/finch/Finch.html#start_link/1-pool-configuration-options) for further information.
