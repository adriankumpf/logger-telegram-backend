defmodule LoggerTelegramBackendTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  require Logger

  defmodule TestClient do
    @behaviour LoggerTelegramBackend.HTTPClient

    @impl true
    def child_spec(pool_opts) do
      send(:logger_telegram_backend_test, {:child_spec, pool_opts})
      Finch.child_spec(name: __MODULE__)
    end

    @impl true
    def request(_method, _url, _headers, body, opts) do
      decoded_body = URI.decode_query(body)
      send(:logger_telegram_backend_test, {:request, decoded_body, opts})
      {:ok, 200, [], []}
    end
  end

  defmodule ErrorTestClient do
    @behaviour LoggerTelegramBackend.HTTPClient

    @impl true
    def child_spec(_pool_opts), do: Finch.child_spec(name: __MODULE__)

    @impl true
    def request(_method, _url, _headers, _body, _opts) do
      {:ok, 503, [], ~s'{"error": "timeout"}'}
    end
  end

  defmodule NoChildSpecTestClient do
    @behaviour LoggerTelegramBackend.HTTPClient

    @impl true
    def child_spec(_pool_opts), do: nil

    @impl true
    def request(_method, _url, _headers, _body, _opts), do: raise("unimplemented")
  end

  def assert_message_sent(message \\ nil, opts \\ []) do
    Logger.flush()

    assert_received {:request, %{"parse_mode" => "HTML", "chat_id" => "$chat_id", "text" => text},
                     ^opts}

    if message do
      assert text == message
    end
  end

  def refute_message_sent do
    Logger.flush()
    refute_received {:request, _body, _opts}
  end

  setup_all do
    Application.stop(:logger_telegram_backend)

    on_exit(fn ->
      Application.start(:logger_telegram_backend)
    end)

    :ok
  end

  @default_config [client: TestClient, chat_id: "$chat_id", token: "$token"]

  setup ctx do
    config = Keyword.merge(@default_config, Map.get(ctx, :config, []))

    application_child_spec = %{
      id: __MODULE__,
      start: {LoggerTelegramBackend.Application, :start, [nil, []]},
      type: :supervisor
    }

    Process.register(self(), :logger_telegram_backend_test)
    Application.put_env(:logger, LoggerTelegramBackend, config)
    start_supervised!(application_child_spec)
    {:ok, _} = LoggerTelegramBackend.attach()

    if System.version() >= "1.15.0" do
      apply(LoggerBackends, :configure, [[truncate: :infinity]])
    else
      apply(Logger, :configure, [[truncate: :infinity]])
      apply(Logger, :remove_backend, [:console])
    end

    on_exit(fn ->
      LoggerTelegramBackend.detach()
      Application.delete_env(:logger, LoggerTelegramBackend)
    end)

    :ok
  end

  @tag config: [client: NoChildSpecTestClient]
  test "allows to return nil from child_spec/1" do
    :ok
  end

  @tag config: [client_pool_opts: [conn_opts: [proxy: {:http, "127.0.0.1", 8888, []}]]]
  test "passes the :client_pool_opts to child_spec/1" do
    assert_received {:child_spec, [conn_opts: [proxy: {:http, "127.0.0.1", 8888, []}]]}
  end

  @tag config: [client_request_opts: [receive_timeout: 5_000]]
  test "passes the :client_request_opts to request/5" do
    Logger.info("foo")
    assert_message_sent(nil, receive_timeout: 5000)
  end

  @tag config: [level: :error]
  test "can be configured at runtime" do
    :ok = LoggerTelegramBackend.configure(level: :debug, metadata: [:user])

    Logger.debug("foo", user: 1)

    assert_message_sent("""
    <b>[debug]</b> <b>foo</b>
    <pre>User: 1</pre>\
    """)
  end

  test "sends the message in HTML format", ctx do
    Logger.error("foobar")
    Logger.flush()

    assert_received {:request, %{"text" => text}, _opts}

    assert text =~ ~r/Line: \d{3}/
    assert text =~ "Function: \"#{ctx.test}/1\""
    assert text =~ "Module: #{inspect(__MODULE__)}"
    assert text =~ "File: #{inspect(__ENV__.file)}"
  end

  @tag config: [metadata: [:function, :module]]
  test "shortens the message if necessary" do
    message = List.duplicate("E", 9999)
    Logger.info(message)

    assert_message_sent("""
    <b>[info]</b> <b>#{List.duplicate("E", 4000)}...</b>
    <pre>Function: \"test shortens the message if necessary/1\"
    Module: LoggerTelegramBackendTest</pre>\
    """)
  end

  @tag config: [metadata: []]
  test "shortens the message based on its graphemes not bytes" do
    for grapheme <- ["A", "é", "💜"] do
      message = List.duplicate(grapheme, 9999)
      Logger.info(message)

      assert_message_sent("""
      <b>[info]</b> <b>#{List.duplicate(grapheme, 4086)}...</b>
      <pre></pre>\
      """)
    end
  end

  @tag config: [metadata: []]
  test "shortens the message and escapes special chars afterwards" do
    message = List.duplicate("&", 9999)
    Logger.info(message)

    assert_message_sent("""
    <b>[info]</b> <b>#{List.duplicate("&amp;", 4086)}...</b>
    <pre></pre>\
    """)
  end

  @tag config: [metadata: [:unsafe]]
  test "escapes special chars in the message and metadata" do
    Logger.info("<msg=&>", unsafe: "<metadata=&>")

    assert_message_sent("""
    <b>[info]</b> <b>&lt;msg=&amp;&gt;</b>
    <pre>Unsafe: \"&lt;metadata=&amp;&gt;\"</pre>\
    """)
  end

  test "logs multiple message smoothly" do
    range = 1..532

    for n <- range, do: Logger.info("#{n}")
    for _ <- range, do: assert_receive({:request, _body, _opts})

    refute_message_sent()
  end

  @tag config: [level: :error]
  test "ignores the message if its level is lower than the configured one" do
    Logger.debug("dbg: foo")
    Logger.info("info: foo")
    refute_message_sent()
  end

  @tag config: [metadata_filter: [foo: :bar]]
  test "ignores the message if the metadata_filter does not match" do
    Logger.debug("dbg: foo")
    Logger.error("error: foo", foo: :baz)
    Logger.info("info: foo", application: :app)
    refute_message_sent()

    Logger.info("info: success", foo: :bar)
    assert_message_sent()
  end

  @tag config: [metadata_filter: [:foo]]
  test "allows filtering by the presence of a metadata key" do
    Logger.debug("dbg: foo")
    refute_message_sent()

    Logger.info("info: success", foo: :bar)
    assert_message_sent()

    Logger.info("info: success", foo: :baz)
    assert_message_sent()
  end

  @tag config: [metadata_filter: [{:foo, 1}, {:bar, 2}, :baz]]
  test "requires all filters to be present" do
    Logger.debug("foo")
    Logger.error("foo", foo: 1)
    Logger.error("foo", bar: 2)
    Logger.error("foo", baz: 3)
    refute_message_sent()

    Logger.info("success", foo: 1, bar: 2, baz: :anything)
    assert_message_sent()
  end

  @tag config: [client: ErrorTestClient]
  test "logs warning if sending fails" do
    assert capture_io(:stderr, fn ->
             Logger.notice("foo")
             Logger.flush()
           end) =~
             ~s'LoggerTelegramBackend failed to send message: "{\\"error\\": \\"timeout\\"}"'
  end
end
