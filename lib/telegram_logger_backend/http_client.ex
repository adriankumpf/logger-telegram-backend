defmodule LoggerTelegramBackend.HTTPClient do
  @moduledoc """
  Specifies the API for using a custom HTTP Client.

  By default, the first HTTP client in the list whose application is loaded is selected:

  - `LoggerTelegramBackend.HTTPClient.Finch` (requires `:finch`)
  - `LoggerTelegramBackend.HTTPClient.Hackney` (requires`:hackney`)

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
  Should return a **child specification** to start the HTTP client or `nil`.

  For example, this can start a pool of HTTP connections dedicated to LoggerTelegramBackend.
  """
  @callback child_spec() :: Supervisor.child_spec() | nil

  @doc """
  Should make an HTTP request to `url` with the given `method`, `headers` and `body`.
  """
  @callback request(method, url, headers, body) :: {:ok, status, headers, body} | {:error, term}
end
