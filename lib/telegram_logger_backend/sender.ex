defmodule LoggerTelegramBackend.Sender do
  @moduledoc false

  @callback send_message(message :: String.t(), opts :: Keyword.t()) :: :ok | {:error, any}
end
