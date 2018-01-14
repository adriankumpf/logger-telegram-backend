defmodule LoggerTelegramBackend.Application do
  @moduledoc false

  use Application

  alias LoggerTelegramBackend.{Formatter, Manager, Sender}

  def start(_type, _args) do
    children = [
      Manager,
      {Formatter, [5, 10]},
      {Sender, [0, 5]}
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 30,
      name: LoggerTelegramBackend.Supervisor
    )
  end
end
