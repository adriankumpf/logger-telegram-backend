# LoggerTelegramBackend

[![Build Status](https://github.com/adriankumpf/logger-telegram-backend/workflows/CI/badge.svg)](https://github.com/adriankumpf/logger-telegram-backend/actions)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/logger_telegram_backend)
[![Hex.pm](https://img.shields.io/hexpm/v/logger_telegram_backend?color=%23714a94)](http://hex.pm/packages/logger_telegram_backend)

A logger backend for [Telegram](https://telegram.org/).

## Installation

Add `:logger_telegram_backend` and `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_telegram_backend, "~> 3.0"},
    {:finch, "~> 0.16"},
  ]
end
```

### Add the backend

In your `Application.start/2` callback, add the `LoggerTelegramBackend`:

```elixir
@impl true
def start(_type, _args) do
  LoggerTelegramBackend.attach()

  # ...
end
```

Add the following to your configuration:

```elixir
config :logger, LoggerTelegramBackend,
  chat_id: "your_chat_id",
  token: "yout_bot_token"
```

To create a Telegram bot, see the next section.

### Configure the Telegram bot

To create a Telegram bot, follow the instructions [here](https://core.telegram.org/bots/features#creating-a-new-bot) and get the `token` for the bot.

Then send a message to the bot and get your `chat_id`:

```bash
TOKEN="your_bot_token"
curl https://api.telegram.org/bot$TOKEN/getUpdates
```

## License

This project is Licensed under the [MIT License](LICENSE).
