defmodule LoggerTelegramBackend.Sender.Telegram do
  @moduledoc false

  @behaviour LoggerTelegramBackend.Sender

  alias LoggerTelegramBackend.Config

  @impl true
  def send_message(text, opts) when is_binary(text) do
    token = Keyword.fetch!(opts, :token)
    chat_id = Keyword.fetch!(opts, :chat_id)

    url = "https://api.telegram.org/bot#{token}/sendMessage"
    headers = [{"content-type", "application/x-www-form-urlencoded"}, {"user-agent", ""}]
    body = URI.encode_query(text: text, chat_id: chat_id, parse_mode: "HTML")

    case Config.client().request(:post, url, headers, body) do
      {:ok, 200, _headers, _body} -> :ok
      {:ok, _status, _headers, body} -> {:error, body}
      {:error, reason} -> {:error, reason}
    end
  end
end
