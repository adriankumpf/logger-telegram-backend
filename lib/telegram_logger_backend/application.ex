defmodule LoggerTelegramBackend.Application do
  @moduledoc false

  use Application

  alias LoggerTelegramBackend.Config

  @impl true
  def start(_type, _opts) do
    client = Config.client()

    if client == LoggerTelegramBackend.HTTPClient.Finch do
      unless Code.ensure_loaded?(Finch) do
        raise """
        LoggerTelegramBackend failed to start. Add :finch to your dependencies to fix this, or \
        configure a different HTTP client.
        """
      end

      with {:error, reason} <- Application.ensure_all_started(:finch) do
        raise "failed to start the :finch application: #{inspect(reason)}"
      end
    end

    children =
      case client.child_spec() do
        nil -> []
        client -> [client]
      end

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: LoggerTelegramBackend.Supervisor
    )
  end
end
