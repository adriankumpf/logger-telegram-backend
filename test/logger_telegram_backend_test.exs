defmodule LoggerTelegramBackendTest do
  use ExUnit.Case

  require Logger

  defmodule TestSender do
    @behaviour LoggerTelegramBackend.Sender

    @impl true
    def send_message(text, opts) do
      send(:logger_telegram_backend_test, {:send_message, text, opts})
      :ok
    end
  end

  setup_all do
    Application.put_env(:logger, :default_handler, false)
    Logger.App.stop()
    Application.start(:logger)

    on_exit(fn ->
      Application.delete_env(:logger, :default_handler)
      Logger.App.stop()
      Application.start(:logger)
    end)
  end

  setup ctx do
    opts =
      ctx
      |> Map.take([:metadata, :metadata_filter, :level])
      |> Map.to_list()
      |> Keyword.merge(sender: {TestSender, []})

    Application.put_env(:logger, LoggerTelegramBackend, opts)
    {:ok, _} = LoggerBackends.add(LoggerTelegramBackend)
    :ok = LoggerBackends.configure(truncate: :infinity)

    on_exit(fn ->
      LoggerBackends.remove(LoggerTelegramBackend)
      Application.delete_env(:logger, LoggerTelegramBackend)
    end)

    Process.register(self(), :logger_telegram_backend_test)

    :ok
  end

  test "logs the message to the specified sender" do
    Logger.info("foo")

    assert_receive {:send_message, "<b>[info]</b> <b>foo</b>" <> _rest, []}
  end

  @tag level: :error
  test "can be configured at runtime" do
    LoggerBackends.configure(LoggerTelegramBackend,
      level: :debug,
      metadata: [:user],
      chat_id: "$chat_id",
      token: "$token",
      sender: {TestSender, [:chat_id, :token]}
    )

    Logger.debug("foo", user: 1)

    assert_receive {:send_message, "<b>[debug]</b> <b>foo</b>\n<pre>User: 1</pre>",
                    [chat_id: "$chat_id", token: "$token"]}
  end

  test "formats the message with markdown" do
    Logger.error("foobar")

    assert_receive {:send_message, message, _}

    assert "<b>[error]</b> <b>foobar</b>\n" <>
             "<pre>" <>
             "Line: " <>
             <<_line::size(16)>> <>
             "\n" <>
             "Function: \"test formats the message with markdown/1\"\n" <>
             "Module: LoggerTelegramBackendTest\n" <> "File:" <> _file = message
  end

  @tag metadata: [:function, :module]
  test "shortens the message if necessary" do
    message = List.duplicate("E", 9999) |> to_string()
    Logger.info(message)

    assert_receive {:send_message, log, _}

    assert log ==
             """
             <b>[info]</b> <b>#{List.duplicate("E", 4000)}...</b>
             <pre>Function: \"test shortens the message if necessary/1\"
             Module: LoggerTelegramBackendTest</pre>
             """
             |> String.trim_trailing()
  end

  @tag metadata: []
  test "shortens the message based on its graphemes not bytes" do
    for grapheme <- ["A", "é", "💜"] do
      message = List.duplicate(grapheme, 9999) |> to_string
      Logger.info(message)

      assert_receive {:send_message, log, _}
      assert log == "<b>[info]</b> <b>#{List.duplicate(grapheme, 4086)}...</b>\n<pre></pre>"
    end
  end

  @tag metadata: []
  test "shortens the message and escapes special chars afterwards" do
    message = List.duplicate("&", 9999) |> to_string
    Logger.info(message)

    assert_receive {:send_message, log, _}
    assert log == "<b>[info]</b> <b>#{List.duplicate("&amp;", 4086)}...</b>\n<pre></pre>"
  end

  @tag metadata: []
  test "escapes special chars in the message" do
    Logger.info("<msg=&>")

    assert_receive {:send_message, message, _}

    assert message ==
             "<b>[info]</b> <b>&lt;msg=&amp;&gt;</b>\n<pre></pre>"
  end

  test "logs multiple message smoothly" do
    range = 1..532

    for n <- range, do: Logger.info("#{n}")
    for _ <- range, do: assert_receive({:send_message, _, _})

    refute_receive {:send_message, _, _}
  end

  @tag level: :error
  test "ignores the message if its level is lower than the configured one" do
    Logger.debug("dbg: foo")
    Logger.info("info: foo")
    Logger.warning("warn: foo")

    refute_receive {:send_message, _, _}
  end

  @tag metadata_filter: [foo: :bar]
  test "ignores the message if the metadata_filter does not match" do
    Logger.debug("dbg: foo")
    Logger.warning("warn: foo", foo: :baz)
    Logger.info("info: foo", application: :app)
    refute_receive {:send_message, _, _}

    Logger.info("info: success", foo: :bar)
    assert_receive {:send_message, _, _}
  end
end
