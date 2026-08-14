defmodule LoggerTelegramBackend.SenderTest do
  use ExUnit.Case, async: true

  alias LoggerTelegramBackend.Sender
  alias LoggerTelegramBackend.Token

  defmodule TestClient do
    @behaviour LoggerTelegramBackend.HTTPClient

    @impl true
    def child_spec(_pool_opts), do: nil

    @impl true
    def request(method, url, headers, body, opts) do
      send(:sender_test, {:request, method, url, headers, body, opts})
      {:ok, 200, [], []}
    end
  end

  setup do
    Process.register(self(), :sender_test)
    {:ok, opts: [client: TestClient, token: Token.new("$token"), chat_id: "$chatId"]}
  end

  test "requires the chat_id", ctx do
    assert_raise RuntimeError, ":chat_id is required", fn ->
      Sender.send_message("foo", Keyword.delete(ctx.opts, :chat_id))
    end
  end

  test "requires the token", ctx do
    assert_raise RuntimeError, ":token is required", fn ->
      Sender.send_message("foo", Keyword.delete(ctx.opts, :token))
    end
  end

  test "requires the client", ctx do
    assert_raise RuntimeError, ":client is required", fn ->
      Sender.send_message("foo", Keyword.delete(ctx.opts, :client))
    end
  end

  test "encodes the body", ctx do
    :ok = Sender.send_message("foo", ctx.opts)

    assert_receive {:request, :post, "https://api.telegram.org/bot$token/sendMessage", headers,
                    body, _opts}

    assert {_, "application/x-www-form-urlencoded"} = List.keyfind(headers, "content-type", 0)

    assert URI.decode_query(body) == %{
             "chat_id" => "$chatId",
             "parse_mode" => "HTML",
             "text" => "foo"
           }
  end

  test "sends a user agent", ctx do
    :ok = Sender.send_message("foo", ctx.opts)
    assert_receive {:request, _method, _url, headers, _body, _opts}

    assert {_, "LoggerTelegramBackend/" <> version} = List.keyfind(headers, "user-agent", 0)
    assert version == Mix.Project.config()[:version]
  end

  test "passes the :client_request_opts to the client", ctx do
    :ok = Sender.send_message("foo", [client_request_opts: [receive_timeout: 5000]] ++ ctx.opts)

    assert_receive {:request, _method, _url, _headers, _body, [receive_timeout: 5000]}
  end
end
