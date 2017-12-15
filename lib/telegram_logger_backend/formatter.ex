defmodule TelegramLoggerBackend.Formatter do
  @moduledoc false

  use GenStage

  alias TelegramLoggerBackend.Logger

  @name __MODULE__

  def start_link([min_demand, max_demand]) do
    GenStage.start_link(__MODULE__, {min_demand, max_demand}, name: @name)
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
      |> Enum.reverse()
      |> Enum.map(&format_event/1)

    {:noreply, formatted_events, state}
  end

  # Private

  defp format_event({sender, %{message: msg, level: level, metadata: metadata}}) do
    msg =
      msg
      |> String.split("\n")
      |> (fn
            [title, rest] -> ["*#{title}*", rest]
            other -> other
          end).()
      |> Enum.join("\n")

    fields =
      Enum.map(metadata ++ [level: level], fn {k, v} ->
        "#{k |> to_string() |> String.capitalize()}: #{inspect(v)}"
      end)
      |> Enum.join("\n")

    text = """
    *#{msg}*
    ```plain
    #{fields}
    ```
    """

    {sender, text}
  end
end
