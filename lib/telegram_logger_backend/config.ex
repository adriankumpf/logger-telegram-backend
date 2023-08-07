defmodule LoggerTelegramBackend.Config do
  @moduledoc false

  def client, do: get_config(:client) || LoggerTelegramBackend.HTTPClient.Finch
  def client_pool_opts, do: get_config(:client_pool_opts, [])
  def client_request_opts, do: get_config(:client_request_opts, [])

  defp get_config(key, default \\ nil) do
    config = Application.get_env(:logger, LoggerTelegramBackend, [])
    Keyword.get(config, key, default)
  end
end
