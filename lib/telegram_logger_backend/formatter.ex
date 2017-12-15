defmodule TelegramLoggerBackend.Formatter do
  @moduledoc false

  use GenStage

  alias TelegramLoggerBackend.Logger

  def start_link([min_demand, max_demand]) do
    GenStage.start_link(__MODULE__, {min_demand, max_demand}, name: __MODULE__)
  end

  # Callbacks

  def init({min_demand, max_demand}) do
    {
      :producer_consumer,
      %{},
      subscribe_to: [{Logger, max_demand: max_demand, min_demand: min_demand}]
    }
  end

  def handle_events(events, _from, state) do
    formatted_events =
      events
      |> Enum.map(fn {url, event} -> {url, format_event(event)} end)
      |> Enum.reverse()

    {:noreply, formatted_events, state}
  end

  # Private

  defp format_event(%{message: msg, level: level, metadata: metadata}) do
    fields =
      Enum.map(metadata ++ [level: level], fn {k, v} ->
        "#{k |> to_string() |> String.capitalize()}: #{inspect(v)}"
      end)  |> Enum.join("\n")

    """
    *#{msg}*
    ```plain
    #{fields}
    ```
    """
  end
end
