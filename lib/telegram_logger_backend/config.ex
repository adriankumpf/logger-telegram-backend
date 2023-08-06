defmodule LoggerTelegramBackend.Config do
  @moduledoc false

  @default_hackney_pool_max_connections 50
  @default_hackney_timeout 5_000

  def client, do: get_config(:client, LoggerTelegramBackend.HackneyClient)

  def hackney_pool_max_connections do
    get_config(:hackney_pool_max_connections, @default_hackney_pool_max_connections)
  end

  def hackney_timeout, do: get_config(:hackney_pool_timeout, @default_hackney_timeout)
  def hackney_opts, do: get_config(:hackney_opts, [])

  defp get_config(key, default) do
    config = Application.get_env(:logger, LoggerTelegramBackend, [])
    Keyword.get(config, key, default)
  end
end
