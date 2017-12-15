defmodule TestSender do
  def send_message(text) do
    send(:telegram_logger_backend_test, {:text, text})
    :ok
  end
end

defmodule TelegramLoggerBackendTest do
  use ExUnit.Case, asyn: false

  require Logger

  setup_all do
    Application.put_env(:logger, :telegram, sender: TestSender, level: :warn)
    {:ok, _} = Logger.add_backend(TelegramLoggerBackend)
    :ok
  end

  test "logs the message to the specified sender" do
    Process.register(self(), :telegram_logger_backend_test)

    Logger.error("foo")

    assert_receive {:text, "*foo*" <> _rest}
  end

  test "formats the message with markdown" do
    Process.register(self(), :telegram_logger_backend_test)

    Logger.error("foobar")

    assert_receive {
                     :text,
                     "*foobar*\n" <>
                       "```plain\n" <>
                       "Line: 30\n" <>
                       "Function: \"test formats the message with markdown/1\"\n" <>
                       "Module: TelegramLoggerBackendTest\n" <>
                       "File: \"/Users/adrian/dev/projects/telegram_logger_backend/test/telegram_logger_backend_test.exs\"\n" <>
                       "Level: :error\n```\n"
                   }
  end

  test "logs multiple message smoothly" do
    Process.register(self(), :telegram_logger_backend_test)

    range = 1..52

    for n <- range, do: Logger.warn("#{n}")
    for n <- range, do: assert_receive({:text, _})

    refute_receive {:text, _}
  end

  test "ignores the message if its level is lower than the configured one" do
    Process.register(self(), :telegram_logger_backend_test)

    Logger.debug("debug: foo")
    Logger.info("info: foo")

    refute_receive {:text, _}
  end
end
