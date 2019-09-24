defmodule LoggerTelegramBackend.HTTPClient.Hackney do
  @moduledoc false

  @behaviour LoggerTelegramBackend.HTTPClient

  if Code.ensure_loaded?(:hackney) do
    @impl true
    def post(url, data, options) do
      case :hackney.request(:post, url, [], {:form, data}, make_options(options)) do
        {:ok, 200, _headers, _client_ref} ->
          :ok

        {:ok, status, _headers, client_ref} ->
          {:error, {:bad_status_code, status, :hackney.body(client_ref)}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp make_options(opts) do
      case Keyword.fetch(opts, :proxy) do
        {:ok, proxy} -> proxy_options(proxy)
        :error -> []
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
  else
    @message """
    missing :hackney dependency

    LoggerTelegramBackend requires a HTTP client.

    In order to use the built-in adapter based on Hackney HTTP client, add the
    following to your mix.exs dependencies list:

        {:hackney, "~> 1.0"}

    See README for more information.
    """

    @impl true
    def post(_url, _headers, _options) do
      raise @message
    end
  end
end
