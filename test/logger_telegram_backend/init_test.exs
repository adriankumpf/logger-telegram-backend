defmodule LoggerTelegramBackend.InitTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn -> Application.delete_env(:logger, LoggerTelegramBackend) end)
  end

  test "attach/1 returns error when :token is missing" do
    Application.put_env(:logger, LoggerTelegramBackend, chat_id: "$chat_id")

    assert {:error, {{:missing_config, :token}, _}} = LoggerTelegramBackend.attach()
  end

  test "attach/1 returns error when :chat_id is missing" do
    Application.put_env(:logger, LoggerTelegramBackend, token: "$token")

    assert {:error, {{:missing_config, :chat_id}, _}} = LoggerTelegramBackend.attach()
  end

  test "attach/1 returns error when config is empty" do
    Application.put_env(:logger, LoggerTelegramBackend, [])

    assert {:error, {{:missing_config, :token}, _}} = LoggerTelegramBackend.attach()
  end
end
