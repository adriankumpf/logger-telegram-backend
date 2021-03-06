defmodule LoggerTelegramBackend.Sender do
  @moduledoc """
  Specifies the API for using a custom Sender.
  """

  @doc """
  Creates a custom Tesla.Client
  """
  @callback client(opts :: Keyword.t()) :: Tesla.Client.t()

  @doc """
  Sends a message
  """
  @callback send_message(
              tesla_client :: Tesla.Client.t(),
              message :: String.t(),
              opts :: Keyword.t()
            ) :: :ok | {:error, any}

  defmacro __using__(opts) do
    quote do
      @behaviour LoggerTelegramBackend.Sender

      @adapter {Tesla.Adapter.Hackney, pool: :logger_telegram_backend}

      @impl true
      def client(opts \\ []) do
        {adapter, opts} = Keyword.pop(opts, :adapter, @adapter)
        {base_url, opts} = Keyword.pop(opts, :base_url, unquote(Keyword.fetch!(opts, :base_url)))

        middlewares = [
          {Tesla.Middleware.BaseUrl, base_url},
          {Tesla.Middleware.Headers, [{"user-agent", ""}]},
          {Tesla.Middleware.Opts, opts}
          | unquote(opts[:middlewares] || [])
        ]

        Tesla.client(middlewares, adapter)
      end

      defoverridable client: 1
    end
  end
end
