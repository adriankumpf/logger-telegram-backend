defmodule LoggerTelegramBackend do
  @external_resource readme = Path.join(__DIR__, "../README.md")

  # The docs live in the README so there is only one copy to keep correct. Everything between the
  # `<!-- MDOC -->` markers is shared; the badges and licence around them are not.
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @behaviour :gen_event

  alias LoggerTelegramBackend.Config
  alias LoggerTelegramBackend.ConfigError
  alias LoggerTelegramBackend.Formatter
  alias LoggerTelegramBackend.Sender
  alias LoggerTelegramBackend.Token

  @doc """
  Adds the LoggerTelegramBackend backend.

  ## Options

    * `:flush` - when `true`, guarantees all messages currently sent
      to `Logger` are processed before the backend is added

  ## Example

      iex> LoggerTelegramBackend.attach()
      {:ok, _pid}

  """
  @doc since: "3.0.0"
  @spec attach(keyword) :: Supervisor.on_start_child()
  def attach(opts \\ []), do: LoggerBackends.add(__MODULE__, opts)

  @doc """
  Removes the LoggerTelegramBackend backend.

  ## Options

    * `:flush` - when `true`, guarantees all messages currently sent
      to `Logger` are processed before the backend is removed

  ## Example

      iex> LoggerTelegramBackend.detach()
      :ok

  """
  @doc since: "3.0.0"
  @spec detach(keyword) :: :ok | {:error, term}
  def detach(opts \\ []), do: LoggerBackends.remove(__MODULE__, opts)

  @doc """
  Applies runtime configuration.

  See the module doc for more information.

  ## Example

      iex> LoggerTelegramBackend.configure(level: :error)
      :ok

  """
  @doc since: "3.0.0"
  @spec configure(keyword) :: :ok | {:error, ConfigError.t()}
  def configure(opts), do: LoggerBackends.configure(__MODULE__, opts)

  @impl :gen_event
  def init(__MODULE__) do
    config = Config.new(Config.read())

    with :ok <- Config.validate(config), do: {:ok, config}
  end

  @impl :gen_event
  def handle_call({:configure, opts}, state) do
    env = Keyword.merge(Config.read(), opts)
    config = Config.new(env)

    case Config.validate(config) do
      :ok ->
        :ok = Application.put_env(:logger, __MODULE__, env)
        {:ok, :ok, config}

      {:error, _reason} = error ->
        {:ok, error, state}
    end
  end

  @impl :gen_event
  def handle_event({_level, gl, _event}, state) when node(gl) != node(), do: {:ok, state}

  def handle_event({level, _gl, {Logger, message, _timestamp, metadata}}, state) do
    level = event_level(metadata, level)

    if meet_level?(level, state.level) and metadata_matches?(metadata, state.metadata_filter) do
      log_event(level, message, metadata, state)
    end

    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}

  @impl :gen_event
  def handle_info(_message, state), do: {:ok, state}

  # `LoggerBackends` collapses the eight `Logger` levels into four before dispatching to a
  # backend, but keeps the original in the metadata. Recovering it means `:level` and the
  # rendered tag say what the caller actually wrote. `LoggerBackends.Console` does the same.
  defp event_level(metadata, collapsed) do
    Keyword.get_lazy(metadata, :erl_level, fn -> Config.normalize_level(collapsed) end)
  end

  defp meet_level?(_level, nil), do: true
  defp meet_level?(level, min), do: Logger.compare_levels(level, min) != :lt

  defp metadata_matches?(metadata, filter) do
    Enum.all?(filter, fn
      {key, value} -> Keyword.fetch(metadata, key) == {:ok, value}
      key -> Keyword.has_key?(metadata, key)
    end)
  end

  # Nothing in here may raise. `LoggerBackends` supervises the handler and re-adds it after a
  # crash, and the resulting crash report is itself an error event this backend receives, so a
  # raise turns into a loop that drowns out the log it was meant to forward.
  defp log_event(level, message, metadata, state) do
    metadata = take_metadata(metadata, state.metadata)
    text = Formatter.format_event(message, level, metadata)

    with {:error, reason} <- Sender.send_message(text, state) do
      report_failure(reason, state.token)
    end
  rescue
    exception -> report_failure(exception, state.token)
  catch
    kind, reason -> report_failure({kind, reason}, state.token)
  end

  # Reported to stderr rather than through `Logger`, which would feed straight back into this
  # backend.
  defp report_failure(reason, token) do
    message = "#{inspect(__MODULE__)} failed to send message: #{inspect(reason)}"
    IO.puts(:stderr, Token.redact(message, token))
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    Enum.flat_map(keys, fn key ->
      case Keyword.fetch(metadata, key) do
        {:ok, value} -> [{key, value}]
        :error -> []
      end
    end)
  end
end
