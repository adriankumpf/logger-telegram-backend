defmodule LoggerTelegramBackend.SenderTest do
  use ExUnit.Case, async: false

  alias LoggerTelegramBackend.Sender

  defmodule TestClient do
    @behaviour LoggerTelegramBackend.HTTPClient

    @impl true
    def child_spec(_pool_opts), do: nil

    @impl true
    def request(method, url, headers, body, opts) do
      send(SenderTest, {:request, method, url, headers, body, opts})
      {:ok, 200, [], []}
    end
  end

  setup do
    Process.register(self(), SenderTest)

    Application.put_env(:logger, LoggerTelegramBackend, client: TestClient)

    on_exit(fn ->
      Application.delete_env(:logger, LoggerTelegramBackend)
    end)
  end

  test "requires the chat_id" do
    assert_raise RuntimeError, ":chat_id is required", fn ->
      Sender.send_message("foo", token: "$token")
    end
  end

  test "requires the token" do
    assert_raise RuntimeError, ":token is required", fn ->
      Sender.send_message("foo", chat_id: "$chat_id")
    end
  end

  test "encodes the body" do
    :ok = Sender.send_message("foo", token: "$token", chat_id: "$chatId")

    assert_receive {:request, :post, "https://api.telegram.org/bot$token/sendMessage", headers,
                    body, _opts}

    assert {_, "application/x-www-form-urlencoded"} = List.keyfind(headers, "content-type", 0)

    assert URI.decode_query(body) == %{
             "chat_id" => "$chatId",
             "parse_mode" => "HTML",
             "text" => "foo"
           }
  end

  test "sends a user agent" do
    :ok = Sender.send_message("foo", token: "$token", chat_id: "$chatId")
    assert_receive {:request, _method, _url, headers, _body, _opts}

    assert {_, "LoggerTelegramBackend/" <> version} = List.keyfind(headers, "user-agent", 0)
    assert version == Mix.Project.config()[:version]
  end

  test "passes the :client_request_opts to the client" do
    :ok =
      Sender.send_message("foo",
        token: "$token",
        chat_id: "$chatId",
        client_request_opts: [receive_timeout: 5000]
      )

    assert_receive {:request, _method, _url, _headers, _body, [receive_timeout: 5000]}
  end
end
