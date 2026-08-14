defmodule LoggerTelegramBackend.InitTest do
  use ExUnit.Case, async: false

  alias LoggerTelegramBackend.ConfigError

  setup do
    on_exit(fn -> Application.delete_env(:logger, LoggerTelegramBackend) end)
  end

  test "attach/1 returns an actionable error when the configuration is incomplete" do
    Application.put_env(:logger, LoggerTelegramBackend, chat_id: "$chat_id")

    assert {:error, {%ConfigError{message: message}, _}} = LoggerTelegramBackend.attach()
    assert message =~ ":token is missing"
    assert message =~ "config :logger, LoggerTelegramBackend"
  end

  test "attach/1 returns an error for an unknown :level" do
    Application.put_env(:logger, LoggerTelegramBackend,
      token: "$token",
      chat_id: "$chat_id",
      level: :bogus
    )

    assert {:error, {%ConfigError{message: message}, _}} = LoggerTelegramBackend.attach()
    assert message =~ "invalid :level :bogus"
  end

  test "the handler state never exposes the token" do
    Application.put_env(:logger, LoggerTelegramBackend,
      token: "s3cr3t-bot-token",
      chat_id: "$chat_id"
    )

    assert {:ok, _} = LoggerTelegramBackend.attach()

    on_exit(fn -> LoggerTelegramBackend.detach() end)

    {:status, _pid, _mod, status} = :sys.get_status(LoggerBackends)
    refute inspect(status, limit: :infinity, printable_limit: :infinity) =~ "s3cr3t-bot-token"

    state = :sys.get_state(LoggerBackends)
    refute inspect(state, limit: :infinity, printable_limit: :infinity) =~ "s3cr3t-bot-token"
  end
end
