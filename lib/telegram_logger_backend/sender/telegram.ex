defmodule LoggerTelegramBackend.Sender.Telegram do
  @moduledoc false

  alias HTTPoison.{Response, Error}

  def send_message(text, token, chat_id) when is_binary(text) do
    post("https://api.telegram.org/bot#{token}/sendMessage",
      text: text,
      chat_id: chat_id,
      parse_mode: "HTML"
    )
  end

  defp post(url, data) do
    case HTTPoison.post(url, {:form, data}) do
      {:ok, %Response{status_code: 200}} -> :ok
      {:ok, %Response{body: body, status_code: code}} -> {:error, {:bad_status_code, code, body}}
      {:error, %Error{reason: reason}} -> {:error, reason}
    end
  end
end
