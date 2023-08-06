defmodule LoggerTelegramBackend.HackneyClient do
  @moduledoc """
  The built-in HTTP client.

  This client implements the `LoggerTelegramBackend.HTTPClient` behaviour.

  It's based on the [hackney](https://github.com/benoitc/hackney) Erlang HTTP client,
  which is an *optional dependency* of this library.

  See `LoggerTelegramBackend` for the available configuration options.

  See the documentation for `LoggerTelegramBackend.HTTPClient` if you wish to use another HTTP
  client.
  """

  alias LoggerTelegramBackend.Config

  @behaviour LoggerTelegramBackend.HTTPClient

  @hackney_pool_name :logger_telegram_backend_pool

  @impl true
  def child_spec do
    ensure_hackney_is_available!()

    :hackney_pool.child_spec(@hackney_pool_name,
      timeout: Config.hackney_timeout(),
      max_connections: Config.hackney_pool_max_connections()
    )
  end

  @impl true
  def request(method, url, headers, body) do
    opts = Keyword.put_new(Config.hackney_opts(), :pool, @hackney_pool_name) ++ [:with_body]

    case :hackney.request(method, url, headers, body, opts) do
      {:ok, _status, _headers, _body} = result -> result
      {:error, _reason} = error -> error
    end
  end

  defp ensure_hackney_is_available! do
    unless Code.ensure_loaded?(:hackney) do
      raise """
      cannot start the LoggerTelegramBackend application because the HTTP client is set to \
      LoggerTelegramBackend.HackneyClient (which is the default), but the Hackney library is not \
      loaded. Add :hackney to your dependencies to fix this or configure a different HTTP client.
      """
    end

    case Application.ensure_all_started(:hackney) do
      {:ok, _apps} -> :ok
      {:error, reason} -> raise "failed to start the :hackney application: #{inspect(reason)}"
    end
  end
end
