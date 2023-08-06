defmodule LoggerTelegramBackendTest do
  use ExUnit.Case, async: false

  require Logger

  defmodule TestSender do
    @behaviour LoggerTelegramBackend.Sender

    @impl true
    def client(_opts) do
      Tesla.client([])
    end

    @impl true
    def send_message(_client, text, _opts) do
      send(:logger_telegram_backend_test, {:text, text})
      :ok
    end
  end

  setup_all do
    :ok = LoggerBackends.configure(truncate: :infinity)
  end

  setup ctx do
    opts =
      ctx
      |> Map.take([:metadata, :metadata_filter, :level])
      |> Map.to_list()
      |> Keyword.merge(sender: {TestSender, []})

    Application.put_env(:logger, :telegram, opts)
    Process.register(self(), :logger_telegram_backend_test)

    LoggerBackends.remove(LoggerTelegramBackend)
    {:ok, _} = LoggerBackends.add(LoggerTelegramBackend)

    :ok
  end

  test "logs the message to the specified sender" do
    Logger.info("foo")

    assert_receive {:text, "<b>[info]</b> <b>foo</b>" <> _rest}
  end

  test "formats the message with markdown" do
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

  @tag metadata: [:function, :module]
  test "shortens the message if necessary" do
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

  @tag metadata: []
  test "shortens the message based on its graphemes not bytes" do
    for grapheme <- ["A", "é", "💜"] do
      message = List.duplicate(grapheme, 9999) |> to_string
      Logger.info(message)

      assert_receive {:text, log}
      assert log == "<b>[info]</b> <b>#{List.duplicate(grapheme, 4086)}...</b>\n<pre></pre>"
    end
  end

  @tag metadata: []
  test "shortens the message and escapes special chars afterwards" do
    message = List.duplicate("&", 9999) |> to_string
    Logger.info(message)

    assert_receive {:text, log}
    assert log == "<b>[info]</b> <b>#{List.duplicate("&amp;", 4086)}...</b>\n<pre></pre>"
  end

  @tag metadata: []
  test "escapes special chars" do
    Logger.info("<>&")
    Logger.info("<code>FOO</code>")

    assert_receive {:text, "<b>[info]</b> <b>&lt;&gt;&amp;</b>\n<pre></pre>"}
    assert_receive {:text, "<b>[info]</b> <b>&lt;code&gt;FOO&lt;/code&gt;</b>\n<pre></pre>"}
  end

  test "logs multiple message smoothly" do
    range = 1..532

    for n <- range, do: Logger.info("#{n}")
    for _ <- range, do: assert_receive({:text, _})

    refute_receive {:text, _}
  end

  @tag level: :error
  test "ignores the message if its level is lower than the configured one" do
    Logger.debug("dbg: foo")
    Logger.info("info: foo")
    Logger.warning("warn: foo")

    refute_receive {:text, _}
  end

  @tag metadata_filter: [foo: :bar]
  test "ignores the message if the metadata_filter does not match" do
    Logger.debug("dbg: foo")
    Logger.warning("warn: foo", foo: :baz)
    Logger.info("info: foo", application: :app)

    refute_receive {:text, _}

    Logger.info("info: success", foo: :bar)

    assert_receive {:text, _}
  end
end
