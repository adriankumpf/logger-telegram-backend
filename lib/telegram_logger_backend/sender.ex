defmodule LoggerTelegramBackend.Sender do
  @moduledoc false

  alias LoggerTelegramBackend.Config

  @user_agent {"user-agent", "LoggerTelegramBackend/#{Mix.Project.config()[:version]}"}

  def send_message(text, opts) when is_binary(text) do
    token = opts[:token] || raise ":token is required"
    chat_id = opts[:chat_id] || raise ":chat_id is required"
    request_opts = opts[:client_request_opts] || []

    url = "https://api.telegram.org/bot#{token}/sendMessage"
    headers = [{"content-type", "application/x-www-form-urlencoded"}, @user_agent]
    body = URI.encode_query(text: text, chat_id: chat_id, parse_mode: "HTML")

    case Config.client().request(:post, url, headers, body, request_opts) do
      {:ok, 200, _headers, _body} -> :ok
      {:ok, _status, _headers, body} -> {:error, body}
      {:error, reason} -> {:error, reason}
    end
  end
end
