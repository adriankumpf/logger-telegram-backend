defmodule TelegramLoggerBackendTest do
  use ExUnit.Case, async: false

  require Logger

  setup_all do
    Logger.remove_backend(:console)
  end

  setup do
    Logger.remove_backend(TelegramLoggerBackend)
    :ok
  end

  test "logs the message to the specified sender" do
    :ok = configure()

    Logger.info("foo")

    assert_receive {:text, "*[info]* *foo*" <> _rest}
  end

  test "formats the message with markdown" do
    :ok = configure()

    Logger.error("foobar")

    assert_receive {
                     :text,
                     "*[error]* *foobar*\n" <>
                       "```plain\n" <>
                       "Line: " <>
                       <<_line::size(16)>> <>
                       "\n" <>
                       "Function: \"test formats the message with markdown/1\"\n" <>
                       "Module: TelegramLoggerBackendTest\n" <>
                       "File: \"/Users/adrian/dev/projects/telegram_logger_backend/test/telegram_logger_backend_test.exs\"\n```\n"
                   }
  end

  test "logs multiple message smoothly" do
    :ok = configure()

    range = 1..532

    for n <- range, do: Logger.info("#{n}")
    for _ <- range, do: assert_receive({:text, _})

    refute_receive {:text, _}
  end

  test "ignores the message if its level is lower than the configured one" do
    :ok = configure(level: :error)

    Logger.debug("dbg: foo")
    Logger.info("info: foo")
    Logger.warn("warn: foo")

    refute_receive {:text, _}
  end

  test "ignores the message if the metadata_filter does not match" do
    :ok = configure(metadata_filter: [foo: :bar])

    Logger.debug("dbg: foo")
    Logger.warn("warn: foo", foo: :baz)
    Logger.info("info: foo", application: :app)

    refute_receive {:text, _}

    Logger.info("info: success", foo: :bar)

    assert_receive {:text, _}
  end

  defp configure(opts \\ []) do
    with true <- Process.register(self(), :telegram_logger_backend_test),
         :ok <- Application.put_env(:logger, :telegram, Keyword.merge(opts, sender: TestSender)),
         {:ok, _} <- Logger.add_backend(TelegramLoggerBackend) do
      :ok
    end
  end
end

defmodule TestSender do
  def send_message(text) do
    send(:telegram_logger_backend_test, {:text, text})
    :ok
  end
end
