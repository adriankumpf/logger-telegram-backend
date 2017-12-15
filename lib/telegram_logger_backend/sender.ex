defmodule TelegramLoggerBackend.Sender do
  @moduledoc false

  use GenStage

  alias TelegramLoggerBackend.Formatter

  @name __MODULE__

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: @name)
  end

  # Callbacks

  def init([min_demand, max_demand]) do
    {:consumer, %{}, subscribe_to: [{Formatter, min_demand: min_demand, max_demand: max_demand}]}
  end

  def handle_events(events, _from, state) do
    process_events(events, state)
  end

  defp process_events([], state) do
    {:noreply, [], state}
  end

  defp process_events([{sender, text} | events], state) do
    :ok = apply(sender, :send_message, [text])
    process_events(events, state)
  end
end
