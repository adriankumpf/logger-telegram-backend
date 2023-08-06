defmodule LoggerTelegramBackend.HTTPClient.Hackney do
  @moduledoc """
  The built-in HTTP client based on [hackney](https://github.com/benoitc/hackney).

  This client implements the `LoggerTelegramBackend.HTTPClient` behaviour.

  See `LoggerTelegramBackend` for the available configuration options and
  `LoggerTelegramBackend.HTTPClient` if you wish to use another HTTP client.
  """

  alias LoggerTelegramBackend.Config

  @behaviour LoggerTelegramBackend.HTTPClient

  @hackney_pool_name :logger_telegram_backend_pool

  @impl true
  def child_spec do
    opts = Config.client_pool_opts()
    :hackney_pool.child_spec(@hackney_pool_name, opts)
  end

  @impl true
  def request(method, url, headers, body) do
    opts =
      Config.client_request_opts()
      |> Keyword.put_new(:pool, @hackney_pool_name)
      |> Enum.concat([:with_body])

    case :hackney.request(method, url, headers, body, opts) do
      {:ok, _status, _headers, _body} = result -> result
      {:error, _reason} = error -> error
    end
  end
end
