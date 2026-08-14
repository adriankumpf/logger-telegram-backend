defmodule LoggerTelegramBackend.Sender do
  @moduledoc false

  alias LoggerTelegramBackend.Token

  @user_agent {"user-agent", "LoggerTelegramBackend/#{Mix.Project.config()[:version]}"}
  @headers [{"content-type", "application/x-www-form-urlencoded"}, @user_agent]

  @spec send_message(String.t(), keyword) :: :ok | {:error, term}
  def send_message(text, opts) when is_binary(text) do
    client = opts[:client] || raise ":client is required"
    token = opts[:token] || raise ":token is required"
    chat_id = opts[:chat_id] || raise ":chat_id is required"
    request_opts = opts[:client_request_opts] || []

    url = "https://api.telegram.org/bot#{Token.reveal(token)}/sendMessage"
    body = URI.encode_query(text: text, chat_id: chat_id, parse_mode: "HTML")

    case client.request(:post, url, @headers, body, request_opts) do
      {:ok, 200, _headers, _body} -> :ok
      {:ok, _status, _headers, body} -> {:error, body}
      {:error, reason} -> {:error, reason}
    end
  end
end
