defmodule TelegramLoggerBackend.Formatter do
  @moduledoc false

  use GenStage

  alias TelegramLoggerBackend.Manager

  @name __MODULE__

  def start_link([min_demand, max_demand]) do
    GenStage.start_link(__MODULE__, {min_demand, max_demand}, name: @name)
  end

  # Callbacks

  def init({min_demand, max_demand}) do
    {
      :producer_consumer,
      %{},
      subscribe_to: [{Manager, min_demand: min_demand, max_demand: max_demand}]
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

  defp format_event({sender, %{level: lvl, message: msg, metadata: md}}) do
    text = """
    *[#{lvl}]* #{format_message(msg)}
    ```plain
    #{format_metadata(md)}
    ```
    """

    {sender, text}
  end

  defp format_message(msg) do
    msg
    |> to_string
    |> String.split("\n")
    |> highlight_title()
    |> Enum.join("\n")
    |> String.trim()
  end

  defp highlight_title([title]), do: ["*#{title}*"]
  defp highlight_title([title | rest]), do: ["*#{title}*"] ++ rest

  defp format_metadata(metadata) do
    metadata
    |> Enum.map(fn {k, v} -> "#{k |> to_string() |> String.capitalize()}: #{inspect(v)}" end)
    |> Enum.join("\n")
  end
end
