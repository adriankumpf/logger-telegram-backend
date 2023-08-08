# Changelog

## 3.0.0 - unreleased

### Upgrade Instructions

#### Dependencies

LoggerTelegramBackend now ships with an HTTP client based on `:finch` instead of `:hackney`.

Add `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_telegram_backend, "~> 3.0-rc"},
    {:finch, "~> 0.16"},
  ]
end
```

#### Adding the backend

1. In your `Application.start/2` callback, add the `LoggerTelegramBackend` backend:

   ```elixir
   @impl true
   def start(_type, _args) do
     LoggerTelegramBackend.attach()

     # ...
   end
   ```

2. Remove the `:backends` configuration from `:logger`:

   ```diff
   config :logger,
   - backends: [LoggerTelegramBackend, :console]
   ```

#### Config

Configuration is now done via `config :logger, LoggerTelegramBackend`.

```diff
- config :logger, :telegram,
+ config :logger, LoggerTelegramBackend,
    # ...
```

#### HTTP client (optional)

1. Remove the `:adapter` configuration and
2. Add the `:client` option and pass your own module that implements the `LoggerTelegramBackend.HTTPClient` behaviour

```diff
config :logger, LoggerTelegramBackend,
-  adapter: {Tesla.Adapter.Gun, []}
+  client: MyGunAdapter
```

See the documentation for `LoggerTelegramBackend.HTTPClient` for more information.

#### Proxy (optional)

1. Remove the `:proxy` configuration
2. Add the `:client_pool_opts` configuration

```diff
config :logger, LoggerTelegramBackend,
-  proxy: "socks5://127.0.0.1:9050"
+  client_pool_opts: [conn_opts: [proxy: {:http, "127.0.0.1", 9050, []}]]
```

## [3.0.0-rc.2] - 2023-08-07

- Remove hackney client
- Pass client opts to callback implementations
- Set user agent
- Wrap LoggerBackends functions
- Run tests on Elixir 1.10 / OTP 21

## [3.0.0-rc.1] - 2023-08-07

### Changes

- Add HTTP client for `Finch`

## [3.0.0-rc.0] - 2023-08-06

### Breaking Changes

- Allow to customize the HTTP client
- Remove `:proxy` option

### Changes

- Log a warning if sending fails

### Bug fixes

- Escape metadata fields
- Fix deprecation warnings

## [2.0.1] - 2021-05-02

### Fixed

- Don't crash if sending an event does not succeed

## [2.0.0] - 2020-12-22

### Changed

- Use [tesla](https://github.com/teamon/tesla) to make the underlying HTTP client configurable

### Breaking Changes

- Make hackney an optional dependency. To use the default `hackney` based adapter, add it to the list of dependencies:

  ```elixir
  def deps do
    [
      {:logger_telegram_backend, "~> 2.0.0"},
      {:hackney, "~> 1.17"}
    ]
  end
  ```

## [1.3.0] - 2019-07-22

### Changed

- Respect maximum message length to avoid [MESSAGE_TOO_LONG errors](https://core.telegram.org/method/messages.sendMessage#return-errors)
- Bump ex_doc from 0.20.2 to 0.21.1

## [1.2.1] - 2019-05-27

### Changed

- Bump httpoison from 1.4.0 to 1.5.1
- Bump ex_doc from 0.19.1 to 0.20.2

## [1.2.0] - 2018-11-28

### Added

- Add proxy support (from [@mvalitov](https://github.com/mvalitov))

## [1.1.0] - 2018-11-26

### Changed

- Remove dependency on `Poison`: the success of a request is now solely determined by the HTTP status code.
- Remove `GenStage` and simplify the overall event handling logic
- Update dependencies

## [1.0.3] - 2018-05-25

### Added

- Add `@impl` attributes

### Changed

- Update dependencies
- Format code

### Fixed

- Fix typo in README

## [1.0.2] - 2018-03-01

### Changed

- Update `httpoison` to 1.0

## [1.0.1] - 2018-02-10

### Changed

- Update Dependencies

## [1.0.0] - 2018-01-14

[3.0.0-rc.2]: https://github.com/adriankumpf/logger-telegram-backend/compare/v3.0.0-rc.1...v3.0.0-rc.2
[3.0.0-rc.1]: https://github.com/adriankumpf/logger-telegram-backend/compare/v3.0.0-rc.0...v3.0.0-rc.1
[3.0.0-rc.0]: https://github.com/adriankumpf/logger-telegram-backend/compare/v2.0.1...v3.0.0-rc.0
[2.0.1]: https://github.com/adriankumpf/logger-telegram-backend/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.3.0...v2.0.0
[1.3.0]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/adriankumpf/logger-telegram-backend/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/adriankumpf/logger-telegram-backend/compare/v0.1.0...v1.0.0
