defmodule LoggerTelegramBackend.Formatter do
  @moduledoc false

  use GenStage

  alias LoggerTelegramBackend.Manager

  def start_link([min_demand, max_demand]) do
    GenStage.start_link(__MODULE__, {min_demand, max_demand}, name: __MODULE__)
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

  defp format_event({sender, args, %{level: lvl, message: msg, metadata: md}}) do
    text = """
    <b>[#{lvl}]</b> #{format_message(msg)}
    <pre>#{format_metadata(md)}</pre>
    """

    {sender, args, text}
  end

  defp format_message(msg) do
    msg
    |> to_string
    |> String.trim()
    |> escape_special_chars()
    |> highlight_title()
  end

  defp escape_special_chars(msg) do
    special_chars = [
      {"&", "&amp;"},
      {"<", "&lt;"},
      {">", "&gt;"}
    ]

    Enum.reduce(special_chars, msg, fn {c, r}, acc ->
      String.replace(acc, c, r)
    end)
  end

  defp highlight_title(msg) do
    msg
    |> String.split("\n")
    |> do_highlight_title()
    |> Enum.join("\n")
  end

  defp do_highlight_title([title]), do: ["<b>#{title}</b>"]
  defp do_highlight_title([title | rest]), do: ["<b>#{title}</b>"] ++ rest

  defp format_metadata(metadata) do
    metadata
    |> Enum.map(fn {k, v} -> "#{k |> to_string() |> String.capitalize()}: #{inspect(v)}" end)
    |> Enum.join("\n")
  end
end
