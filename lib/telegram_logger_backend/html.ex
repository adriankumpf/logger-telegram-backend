defmodule LoggerTelegramBackend.HTML do
  @moduledoc false

  @escapes %{"&" => "&amp;", "<" => "&lt;", ">" => "&gt;"}

  @spec escape(binary) :: binary
  def escape(bin) when is_binary(bin) do
    String.replace(bin, Map.keys(@escapes), &Map.fetch!(@escapes, &1))
  end
end
