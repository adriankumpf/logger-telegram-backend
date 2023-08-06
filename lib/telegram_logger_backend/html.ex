defmodule LoggerTelegramBackend.HTML do
  @moduledoc false

  @spec escape(binary) :: binary
  def escape(bin) when is_binary(bin) do
    bin
    |> escape(0, bin, [])
    |> IO.iodata_to_binary()
  end

  escapes = [
    {?&, "&amp;"},
    {?<, "&lt;"},
    {?>, "&gt;"}
  ]

  for {match, insert} <- escapes do
    defp escape(<<unquote(match), rest::bits>>, skip, original, acc) do
      escape(rest, skip + 1, original, [acc | unquote(insert)])
    end
  end

  defp escape(<<_char, rest::bits>>, skip, original, acc) do
    escape(rest, skip, original, acc, 1)
  end

  defp escape(<<>>, _skip, _original, acc) do
    acc
  end

  for {match, insert} <- escapes do
    defp escape(<<unquote(match), rest::bits>>, skip, original, acc, len) do
      part = binary_part(original, skip, len)
      escape(rest, skip + len + 1, original, [acc, part | unquote(insert)])
    end
  end

  defp escape(<<_char, rest::bits>>, skip, original, acc, len) do
    escape(rest, skip, original, acc, len + 1)
  end

  defp escape(<<>>, 0, original, _acc, _len) do
    original
  end

  defp escape(<<>>, skip, original, acc, len) do
    [acc | binary_part(original, skip, len)]
  end
end
