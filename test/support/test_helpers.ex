defmodule LoggerTelegramBackend.TestHelpers do
  @moduledoc false

  @doc """
  Approximates Telegram's display length by stripping HTML tags and
  decoding a single level of entities to avoid double-decoding issues.
  """
  def display_length(html) do
    html
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace(~r/&(amp|lt|gt);/, fn
      "&amp;" -> "&"
      "&lt;" -> "<"
      "&gt;" -> ">"
    end)
    |> String.length()
  end
end
