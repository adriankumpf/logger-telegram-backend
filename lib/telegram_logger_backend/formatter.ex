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
    budget = @max_length - String.length(level_tag) - separator_cost(metadata)

    metadata_text =
      metadata
      |> format_metadata()
      |> truncate(budget - @reserved_for_message)

    message_text =
      message
      |> to_string()
      |> String.trim()
      |> truncate(budget - String.length(metadata_text))

    header = "<b>#{level_tag}</b> #{message_text |> HTML.escape() |> highlight_title()}"

    case metadata_text do
      "" -> header
      text -> header <> "\n<pre>#{HTML.escape(text)}</pre>"
    end
  end

  # " " between level and message; "\n" before metadata only when present.
  defp separator_cost([]), do: 1
  defp separator_cost(_), do: 2

  defp highlight_title(text) do
    case String.split(text, "\n", parts: 2) do
      [single] -> "<b>#{single}</b>"
      [title, rest] -> "<b>#{title}</b>\n#{rest}"
    end
  end

  defp format_metadata(metadata) do
    Enum.map_join(metadata, "\n", fn {key, value} ->
      label = key |> to_string() |> String.capitalize()
      # `metadata: :all` includes `:crash_reason`, which inspects to a full stacktrace that
      # truncation would only throw away again.
      "#{label}: #{inspect(value, limit: 25, printable_limit: @max_length)}"
    end)
  end

  # NOTE: Uses String.length/1 (grapheme count). Telegram's docs say "characters"
  # without specifying grapheme vs code point — we assume graphemes.
  defp truncate(_str, max) when max <= 0, do: ""

  defp truncate(str, max) do
    cond do
      # A grapheme is never shorter than a byte, so a binary this small always fits. Skips the
      # O(n) grapheme walk for the common case of a short log message.
      byte_size(str) <= max -> str
      String.length(str) <= max -> str
      true -> String.slice(str, 0, max - 1) <> "…"
    end
  end
end
