defmodule LoggerTelegramBackend.Sender.Telegram do
  @moduledoc false

  use LoggerTelegramBackend.Sender,
    base_url: "https://api.telegram.org",
    middlewares: [Tesla.Middleware.FormUrlencoded],
    adapter: {Tesla.Adapter.Hackney, pool: :logger_telegram_backend}

  @impl true
  def send_message(client, text, opts) when is_binary(text) do
    token = Keyword.fetch!(opts, :token)
    chat_id = Keyword.fetch!(opts, :chat_id)

    response =
      Tesla.request(client,
        method: :post,
        url: "/bot#{token}/sendMessage",
        body: [text: text, chat_id: chat_id, parse_mode: "HTML"],
        opts: make_options(opts)
      )

    case response do
      {:ok, %Tesla.Env{status: 200}} -> :ok
      {:ok, %Tesla.Env{body: body}} -> {:error, body}
      {:error, reason} -> {:error, reason}
    end
  end

  defp make_options(opts) do
    case Keyword.fetch(opts, :proxy) do
      :error ->
        []

      {:ok, proxy} ->
        uri = URI.parse(proxy)

        proxy =
          case uri.scheme do
            "socks5" -> {:socks5, String.to_charlist(uri.host), uri.port}
            _other -> String.to_charlist(proxy)
          end

        [ssl: [verify: :verify_none], hackney: [insecure: true], proxy: proxy]
    end
  end
end
