defmodule LoggerTelegramBackend.HTTPClient do
  @moduledoc false

  @callback post(url :: String.t(), data :: keyword(), options :: keyword()) ::
              :ok | {:error, any()}
end
