defmodule LoggerTelegramBackendTest do
  use ExUnit.Case, async: false

  require Logger

  setup_all do
    :ok = Logger.configure(truncate: :infinity)
    :ok = Logger.remove_backend(:console)
  end

  test "logs the message to the specified sender" do
    :ok = configure()

    Logger.info("foo")

    assert_receive {:text, "<b>[info]</b> <b>foo</b>" <> _rest}
  end

  test "formats the message with markdown" do
    :ok = configure()

    Logger.error("foobar")

    assert_receive {
      :text,
      "<b>[error]</b> <b>foobar</b>\n" <>
        "<pre>" <>
        "Line: " <>
        <<_line::size(16)>> <>
        "\n" <>
        "Function: \"test formats the message with markdown/1\"\n" <>
        "Module: LoggerTelegramBackendTest\n" <> "File:" <> _file
    }
  end

  test "shortens the message if necessary" do
    :ok = configure(metadata: [:function, :module])

    message = List.duplicate("E", 9999) |> to_string
    Logger.info(message)
    assert_receive {:text, log}

    assert log ==
             """
             <b>[info]</b> <b>#{List.duplicate("E", 4000)}...</b>
             <pre>Function: \"test shortens the message if necessary/1\"
             Module: LoggerTelegramBackendTest</pre>
             """
             |> String.trim_trailing()
  end

  test "shortens the message based on its graphemes not bytes" do
    :ok = configure(metadata: [])

    for grapheme <- ["A", "é", "💜"] do
      message = List.duplicate(grapheme, 9999) |> to_string
      Logger.info(message)

      assert_receive {:text, log}
      assert log == "<b>[info]</b> <b>#{List.duplicate(grapheme, 4086)}...</b>\n<pre></pre>"
    end
  end

  test "shortens the message and escapes special chars afterwards" do
    :ok = configure(metadata: [])

    message = List.duplicate("&", 9999) |> to_string
    Logger.info(message)

    assert_receive {:text, log}
    assert log == "<b>[info]</b> <b>#{List.duplicate("&amp;", 4086)}...</b>\n<pre></pre>"
  end

  test "escapes special chars" do
    :ok = configure(metadata: [])

    Logger.info("<>&")
    Logger.info("<code>FOO</code>")

    assert_receive {:text, "<b>[info]</b> <b>&lt;&gt;&amp;</b>\n<pre></pre>"}
    assert_receive {:text, "<b>[info]</b> <b>&lt;code&gt;FOO&lt;/code&gt;</b>\n<pre></pre>"}
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
    with true <- Process.register(self(), :logger_telegram_backend_test),
         :ok <-
           Application.put_env(:logger, :telegram, Keyword.merge(opts, sender: {TestSender, []})),
         _ <- Logger.remove_backend(LoggerTelegramBackend),
         {:ok, _} <- Logger.add_backend(LoggerTelegramBackend) do
      :ok
    end
  end
end

defmodule TestSender do
  def send_message(text, _opts) do
    send(:logger_telegram_backend_test, {:text, text})
    :ok
  end
end
