defmodule LoggerTelegramBackend.Formatter do
  @moduledoc false

  alias LoggerTelegramBackend.HTML

  @max_length 4096

  def format_event(message, level, metadata) do
    level_str = "[#{level}]"
    metadata_str = format_metadata(metadata)

    max_length = @max_length - String.length(level_str) - String.length(metadata_str) - 1
    message_str = format_message(message, max_length)

    "<b>#{level_str}</b> " <> message_str <> "\n<pre>#{metadata_str}</pre>"
  end

  defp format_metadata(metadata) do
    metadata
    |> Enum.map(fn {k, v} -> "#{k |> to_string() |> String.capitalize()}: #{inspect(v)}" end)
    |> Enum.join("\n")
    |> HTML.escape()
  end

  defp format_message(message, max_length) do
    message
    |> to_string
    |> String.trim()
    |> limit_length(max_length)
    |> HTML.escape()
    |> highlight_title()
  end

  defp limit_length(str, max) do
    case String.split_at(str, max - 3) do
      {m, ""} -> m
      {m, _} -> m <> "..."
    end
  end

  defp highlight_title(message) do
    message
    |> String.split("\n")
    |> do_highlight_title()
    |> Enum.join("\n")
  end

  defp do_highlight_title([title]), do: ["<b>#{title}</b>"]
  defp do_highlight_title([title | rest]), do: ["<b>#{title}</b>"] ++ rest
end
