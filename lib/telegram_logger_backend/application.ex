defmodule LoggerTelegramBackend.Application do
  @moduledoc false

  use Application

  alias LoggerTelegramBackend.Config

  @impl true
  def start(_type, _opts) do
    children =
      case Config.client().child_spec() do
        nil -> []
        client -> [client]
      end

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: LoggerTelegramBackend.Supervisor
    )
  end
end
