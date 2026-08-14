defmodule LoggerTelegramBackend.ConfigError do
  @moduledoc """
  Returned by `LoggerTelegramBackend.attach/1` and `LoggerTelegramBackend.configure/1` when an
  option is missing or invalid.

  See `LoggerTelegramBackend` for the available options.
  """

  defexception [:message]

  @type t :: %__MODULE__{message: String.t()}
end
