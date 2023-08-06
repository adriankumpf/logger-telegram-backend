defmodule LoggerTelegramBackend.HTTPClient do
  @moduledoc """
  Specifies the API for using a custom HTTP Client.

  The default HTTP client is `LoggerTelegramBackend.HackneyClient`

  To configure a different HTTP client, implement the `LoggerTelegramBackend.HTTPClient` behaviour
  and change the `:client` configuration:

      config :logger, LoggerTelegramBackend,
        client: MyHTTPClient
  """

  @typedoc """
  HTTP request method.
  """
  @type method :: atom

  @typedoc """
  HTTP request URL.
  """
  @type url :: String.t()

  @typedoc """
  HTTP response status.
  """
  @type status :: 100..599

  @typedoc """
  HTTP request or response headers.
  """
  @type headers :: [{String.t(), String.t()}]

  @typedoc """
  HTTP request or response body.
  """
  @type body :: binary()

  @doc """
  Should return a **child specification** to start the HTTP client.

  For example, this can start a pool of HTTP connections dedicated to LoggerTelegramBackend.
  """
  @callback child_spec() :: Supervisor.child_spec()

  @doc """
  Should make an HTTP request to `url` with the given `method`, `headers` and `body`.
  """
  @callback request(method, url, headers, body) :: {:ok, status, headers, body} | {:error, term}
end
