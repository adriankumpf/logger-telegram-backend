defmodule LoggerTelegramBackend.Config do
  @moduledoc false

  # Every option lives under one application env key. `all/0` is the single place that reads it;
  # the accessors below are pure so callers can resolve a whole config in one read.

  @default_client LoggerTelegramBackend.HTTPClient.Finch

  def all, do: Application.get_env(:logger, LoggerTelegramBackend, [])

  def client(config), do: Keyword.get(config, :client, @default_client)

  def client_pool_opts(config), do: Keyword.get(config, :client_pool_opts, [])
end
