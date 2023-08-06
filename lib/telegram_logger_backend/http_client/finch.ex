defmodule LoggerTelegramBackend.HTTPClient.Finch do
  @moduledoc """
  The built-in HTTP client based on [finch](https://github.com/sneako/finch).

  This client implements the `LoggerTelegramBackend.HTTPClient` behaviour.

  See `LoggerTelegramBackend` for the available configuration options and
  `LoggerTelegramBackend.HTTPClient` if you wish to use another HTTP client.
  """
  @behaviour LoggerTelegramBackend.HTTPClient

  alias LoggerTelegramBackend.Config

  @finch_pool_name LoggerTelegramBackend.Finch

  @impl true
  def child_spec do
    opts = Config.client_pool_opts() |> Keyword.put(:name, @finch_pool_name)
    Finch.child_spec(opts)
  end

  @impl true
  def request(method, url, headers, body) do
    req = Finch.build(method, url, headers, body)
    opts = Config.client_request_opts()

    case Finch.request(req, @finch_pool_name, opts) do
      {:ok, %{status: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
