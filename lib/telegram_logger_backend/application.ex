defmodule TelegramLoggerBackend.Application do
  @moduledoc false

  use Application

  alias TelegramLoggerBackend.{Formatter, Logger, Sender}

  def start(_type, _args) do
    children = [
      Logger,
      {Formatter, [5, 10]},
      {Sender, [0, 5]}
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: TelegramLoggerBackend.Supervisor
    )
  end
end
