defmodule LoggerTelegramBackend.Telegram do
  @moduledoc false

  alias HTTPoison.{Response, Error}

  def send_message(text, opts) when is_binary(text) and is_list(opts) do
    token = Keyword.fetch!(opts, :token)

    data = [
      text: text,
      chat_id: Keyword.fetch!(opts, :chat_id),
      parse_mode: "HTML"
    ]

    post("https://api.telegram.org/bot#{token}/sendMessage", data, make_options(opts))
  end

  defp post(url, data, options) do
    case HTTPoison.request(:post, String.to_charlist(url), {:form, data}, [], options) do
      {:ok, %Response{status_code: 200}} -> :ok
      {:ok, %Response{body: body, status_code: code}} -> {:error, {:bad_status_code, code, body}}
      {:error, %Error{reason: reason}} -> {:error, reason}
    end
  end

  defp make_options(opts) do
    case Keyword.fetch(opts, :proxy) do
      :error ->
        []

      {:ok, proxy} ->
        proxy_options(proxy)
    end
  end

  defp proxy_options(proxy) do
    uri = URI.parse(proxy)

    options =
      case uri.scheme do
        "socks5" -> [proxy: {:socks5, String.to_charlist(uri.host), uri.port}]
        _ -> [proxy: String.to_charlist(proxy)]
      end

    [ssl: [verify: :verify_none], hackney: [insecure: true]] ++ options
  end
end
