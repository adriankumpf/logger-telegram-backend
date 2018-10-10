defmodule LoggerTelegramBackend.Telegram do
  @moduledoc false

  alias HTTPoison.{Response, Error}

  def send_message(text, opts) when is_binary(text) and is_list(opts) do
    post("https://api.telegram.org/bot#{Keyword.fetch!(opts, :token)}/sendMessage",
      text: text,
      chat_id: Keyword.fetch!(opts, :chat_id),
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
