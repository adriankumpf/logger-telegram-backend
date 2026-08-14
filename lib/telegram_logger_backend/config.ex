defmodule LoggerTelegramBackend.Config do
  @moduledoc false

  # The resolved configuration, and the only place that knows the defaults. `new/1` is total so
  # that the application can start (and boot the HTTP client pool) even when the backend itself
  # is not configured yet; `validate/1` is what rejects a configuration the backend cannot use.

  alias LoggerTelegramBackend.ConfigError
  alias LoggerTelegramBackend.HTTPClient
  alias LoggerTelegramBackend.Token

  defstruct token: nil,
            chat_id: nil,
            level: nil,
            metadata: [:line, :function, :module, :application, :file],
            metadata_filter: [],
            client: HTTPClient.Finch,
            client_pool_opts: [],
            client_request_opts: []

  @type t :: %__MODULE__{
          token: Token.t() | nil,
          chat_id: term,
          level: Logger.level() | nil,
          metadata: [atom] | :all,
          metadata_filter: keyword | [atom],
          client: module,
          client_pool_opts: keyword,
          client_request_opts: keyword
        }

  @levels [nil | Logger.levels()]

  @spec read() :: keyword
  def read, do: Application.get_env(:logger, LoggerTelegramBackend, [])

  @spec new(keyword) :: t
  def new(env) do
    config = struct(__MODULE__, env)
    %{config | level: normalize_level(config.level), token: wrap_token(config.token)}
  end

  @doc """
  Maps the deprecated `:warn` onto `:warning`.

  `Logger.compare_levels/2` emits a deprecation warning for `:warn`, which would fire on every
  single event.
  """
  @spec normalize_level(atom) :: atom
  def normalize_level(:warn), do: :warning
  def normalize_level(level), do: level

  @spec validate(t) :: :ok | {:error, ConfigError.t()}
  def validate(%__MODULE__{} = config) do
    cond do
      not match?(%Token{}, config.token) ->
        error(":token is missing or is not a string")

      is_nil(config.chat_id) ->
        error(":chat_id is missing")

      config.level not in @levels ->
        error("invalid :level #{inspect(config.level)}, expected one of #{inspect(@levels)}")

      not valid_metadata?(config.metadata) ->
        error("invalid :metadata #{inspect(config.metadata)}, expected a list of atoms or :all")

      not valid_metadata_filter?(config.metadata_filter) ->
        error(
          "invalid :metadata_filter #{inspect(config.metadata_filter)}, " <>
            "expected a list of atoms and/or {atom, value} pairs"
        )

      true ->
        :ok
    end
  end

  defp wrap_token(token) when is_binary(token), do: Token.new(token)
  defp wrap_token(token), do: token

  defp valid_metadata?(:all), do: true
  defp valid_metadata?(metadata), do: is_list(metadata) and Enum.all?(metadata, &is_atom/1)

  defp valid_metadata_filter?(filter) do
    is_list(filter) and
      Enum.all?(filter, fn
        {key, _value} -> is_atom(key)
        key -> is_atom(key)
      end)
  end

  defp error(problem) do
    {:error,
     %ConfigError{
       message: """
       #{problem}.

       Configure LoggerTelegramBackend like this:

           config :logger, LoggerTelegramBackend,
             token: "your_bot_token",
             chat_id: "your_chat_id"
       """
     }}
  end
end
