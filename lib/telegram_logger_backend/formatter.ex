defmodule LoggerTelegramBackend.Formatter do
  @moduledoc false

  def format_event(message, level, metadata) do
    """
    <b>[#{level}]</b> #{format_message(message)}
    <pre>#{format_metadata(metadata)}</pre>
    """
  end

  defp format_message(message) do
    message
    |> to_string
    |> String.trim()
    |> escape_special_chars()
    |> highlight_title()
  end

  defp escape_special_chars(message) do
    special_chars = [
      {"&", "&amp;"},
      {"<", "&lt;"},
      {">", "&gt;"}
    ]

    Enum.reduce(special_chars, message, fn {c, r}, acc ->
      String.replace(acc, c, r)
    end)
  end

  defp highlight_title(message) do
    message
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
