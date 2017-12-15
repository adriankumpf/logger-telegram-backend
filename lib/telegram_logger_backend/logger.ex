defmodule TelegramLoggerBackend.Logger do
  @moduledoc false

  use GenStage

  @name __MODULE__

  @doc """
  Adds a logger event to the queue for sending to Telegram.
  """
  def add_event(event) do
    GenStage.cast(@name, {:add, event})
  end

  # Callbacks

  def start_link(_args) do
    GenStage.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_cast({:add, event}, {queue, demand}) when demand > 0 do
    {:noreply, [event], {queue, demand - 1}}
  end

  def handle_cast({:add, event}, {queue, demand}) do
    {:noreply, [], {:queue.in(event, queue), demand}}
  end

  def handle_demand(incoming_demand, {queue, demand}) when incoming_demand > 0 do
    dispatch_events(queue, incoming_demand + demand, [])
  end

  # Private

  defp dispatch_events(queue, demand, events) when demand > 0 do
    case :queue.out(queue) do
      {:empty, queue} ->
        {:noreply, events, {queue, demand}}

      {{:value, event}, queue} ->
        dispatch_events(queue, demand - 1, [event | events])
    end
  end

  defp dispatch_events(queue, demand, events) do
    {:noreply, events, {queue, demand}}
  end
end
