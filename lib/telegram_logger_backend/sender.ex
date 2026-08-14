defmodule LoggerTelegramBackend.Sender do
  @moduledoc false

  alias LoggerTelegramBackend.Config
  alias LoggerTelegramBackend.Token

  @headers [
    {"content-type", "application/x-www-form-urlencoded"},
    {"user-agent", "LoggerTelegramBackend/#{Mix.Project.config()[:version]}"}
  ]

  @spec send_message(String.t(), Config.t()) :: :ok | {:error, term}
  def send_message(text, %Config{} = config) when is_binary(text) do
    url = "https://api.telegram.org/bot#{Token.reveal(config.token)}/sendMessage"
    body = URI.encode_query(text: text, chat_id: config.chat_id, parse_mode: "HTML")

    case config.client.request(:post, url, @headers, body, config.client_request_opts) do
      {:ok, 200, _headers, _body} -> :ok
      {:ok, _status, _headers, body} -> {:error, body}
      {:error, reason} -> {:error, reason}
    end
  end
end
