defmodule LoggerTelegramBackend.Sender do
  @callback client(Keyword.t()) :: Tesla.Client.t()

  @callback send_message(Tesla.Client.t(), String.t(), Keyword.t()) :: :ok | {:error, any}
end
