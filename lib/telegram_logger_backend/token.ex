defmodule LoggerTelegramBackend.Token do
  @moduledoc false

  # The bot token is a credential: whoever holds it controls the bot. Wrapping it keeps it out of
  # everything that renders a term (`:gen_event` crash reports, `:sys.get_state/1`, exception
  # messages) instead of relying on each of those paths to remember to redact it.

  @enforce_keys [:value]
  defstruct [:value]

  @type t :: %__MODULE__{value: String.t()}

  @spec new(String.t()) :: t
  def new(value) when is_binary(value), do: %__MODULE__{value: value}

  @spec reveal(t) :: String.t()
  def reveal(%__MODULE__{value: value}), do: value

  @doc """
  Replaces every occurrence of the token in `string`.

  For the one place wrapping cannot reach: HTTP clients quote the request URL, which embeds the
  token, in their error terms.
  """
  @spec redact(String.t(), t | nil) :: String.t()
  def redact(string, %__MODULE__{value: value}) when byte_size(value) > 0 do
    String.replace(string, value, "[REDACTED]")
  end

  def redact(string, _token), do: string

  # Deliberately no `String.Chars` implementation: interpolating a token should fail loudly
  # rather than silently put "[REDACTED]" into a request URL.
  defimpl Inspect do
    def inspect(_token, _opts), do: "#LoggerTelegramBackend.Token<[REDACTED]>"
  end
end
