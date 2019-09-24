defmodule LoggerTelegramBackend.Telegram do
  @moduledoc false

  def(send_message(text, opts) when is_binary(text) and is_list(opts)) do
    http_client = Keyword.fetch!(opts, :http_client)
    token = Keyword.fetch!(opts, :token)

    data = [
      text: text,
      chat_id: Keyword.fetch!(opts, :chat_id),
      parse_mode: "HTML"
    ]

    http_client.post("https://api.telegram.org/bot#{token}/sendMessage", data, opts)
  end
end
