defmodule LoggerTelegramBackend.Application do
  @moduledoc false

  use Application

  alias LoggerTelegramBackend.Config

  @impl true
  def start(_type, _opts) do
    config = Config.all()
    client = Config.client(config)

    if client == LoggerTelegramBackend.HTTPClient.Finch, do: ensure_finch_started!()

    children = List.wrap(client.child_spec(Config.client_pool_opts(config)))

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: LoggerTelegramBackend.Supervisor
    )
  end

  defp ensure_finch_started! do
    if not Code.ensure_loaded?(Finch) do
      raise """
      LoggerTelegramBackend failed to start. Add :finch to your dependencies to fix this, or \
      configure a different HTTP client.
      """
    end

    with {:error, reason} <- Application.ensure_all_started(:finch) do
      raise "failed to start the :finch application: #{inspect(reason)}"
    end
  end
end
