defmodule LoggerTelegramBackend.Formatter do
  @moduledoc false

  alias LoggerTelegramBackend.HTML

  # Telegram's sendMessage limit is 4096 characters *after entities parsing*,
  # i.e. display text only — HTML tags and entity encoding don't count.
  @max_length 4096

  # Reserve this many characters so the actual log message is never starved.
  @reserved_for_message 50

  @spec format_event(String.t(), atom, keyword) :: String.t()
  def format_event(message, level, metadata) do
    level_tag = "[#{level}]"
    metadata_text = format_metadata(metadata)

    budget = @max_length - String.length(level_tag) - separator_cost(metadata_text)
    metadata_text = truncate(metadata_text, max(budget - @reserved_for_message, 0))

    message_text =
      message
      |> to_string()
      |> String.trim()
      |> truncate(budget - String.length(metadata_text))

    render(level_tag, message_text, metadata_text)
  end

  # " " between level and message; "\n" before metadata only when present.
  defp separator_cost(""), do: 1
  defp separator_cost(_), do: 2

  defp render(level_tag, message, "") do
    """
    <b>#{level_tag}</b> #{message |> HTML.escape() |> highlight_title()}\
    """
  end

  defp render(level_tag, message, metadata) do
    """
    <b>#{level_tag}</b> #{message |> HTML.escape() |> highlight_title()}
    <pre>#{HTML.escape(metadata)}</pre>\
    """
  end

  defp highlight_title(text) do
    case String.split(text, "\n", parts: 2) do
      [single] -> "<b>#{single}</b>"
      [title, rest] -> "<b>#{title}</b>\n#{rest}"
    end
  end

  defp format_metadata(metadata) do
    Enum.map_join(metadata, "\n", fn {key, value} ->
      label = key |> to_string() |> String.capitalize()
      "#{label}: #{inspect(value)}"
    end)
  end

  # NOTE: Uses String.length/1 (grapheme count). Telegram's docs say "characters"
  # without specifying grapheme vs code point — we assume graphemes.
  defp truncate(_str, max) when max <= 0, do: ""

  defp truncate(str, max) do
    if String.length(str) <= max do
      str
    else
      String.slice(str, 0, max - 1) <> "…"
    end
  end
end
