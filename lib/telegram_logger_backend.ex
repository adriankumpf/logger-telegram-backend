defmodule LoggerTelegramBackend do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @external_resource "README.md"

  @doc """
  Adds the LoggerTelegramBackend backend.

  ## Options

    * `:flush` - when `true`, guarantees all messages currently sent
      to `Logger` are processed before the backend is added

  ## Example

      iex> LoggerTelegramBackend.attach()
      :ok

  """
  @doc since: "3.0.0"
  @spec attach(keyword) :: Supervisor.on_start_child()
  def attach(opts \\ [])

  case System.version() >= "1.15.0" do
    true -> def attach(opts), do: LoggerBackends.add(__MODULE__, opts)
    false -> def attach(opts), do: Logger.add_backend(__MODULE__, opts)
  end

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
  def detach(opts \\ [])

  case System.version() >= "1.15.0" do
    true -> def detach(opts), do: LoggerBackends.remove(__MODULE__, opts)
    false -> def detach(opts), do: Logger.remove_backend(__MODULE__, opts)
  end

  @doc """
  Applies runtime configuration.

  See the module doc for more information.

  ## Example

      iex> LoggerTelegramBackend.configure(level: :error)
      :ok

  """
  @doc since: "3.0.0"
  @spec configure(keyword) :: term
  case System.version() >= "1.15.0" do
    true -> def configure(opts), do: LoggerBackends.configure(__MODULE__, opts)
    false -> def configure(opts), do: Logger.configure_backend(__MODULE__, opts)
  end

  @behaviour :gen_event

  alias LoggerTelegramBackend.Formatter
  alias LoggerTelegramBackend.Sender

  @default_metadata [:line, :function, :module, :application, :file]

  @impl :gen_event
  def init(__MODULE__) do
    config = Application.get_env(:logger, __MODULE__, [])
    {:ok, initialize(config)}
  end

  @impl :gen_event
  def handle_call({:configure, config}, _state) do
    config = Keyword.merge(Application.get_env(:logger, __MODULE__), config)
    :ok = Application.put_env(:logger, __MODULE__, config)
    state = initialize(config)
    {:ok, :ok, state}
  end

  @impl :gen_event
  def handle_event({_level, gl, _event}, state) when node(gl) != node(), do: {:ok, state}

  def handle_event({level, _gl, {Logger, message, timestamp, metadata}}, state) do
    if meet_level?(level, state.level) and metadata_matches?(metadata, state.metadata_filter) do
      log_event(level, message, timestamp, metadata, state)
    end

    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}

  @impl :gen_event
  def handle_info(_message, state), do: {:ok, state}

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(:warn, min), do: meet_level?(:warning, min)
  defp meet_level?(lvl, min), do: Logger.compare_levels(lvl, min) != :lt

  defp metadata_matches?(_metadata, nil), do: true
  defp metadata_matches?(_metadata, []), do: true

  defp metadata_matches?(metadata, [{key, value} | rest]) do
    case Keyword.fetch(metadata, key) do
      {:ok, ^value} -> metadata_matches?(metadata, rest)
      _ -> false
    end
  end

  defp initialize(config) do
    %{
      level: config[:level],
      metadata: config[:metadata] || @default_metadata,
      metadata_filter: config[:metadata_filter],
      sender_opts: Keyword.take(config, [:token, :chat_id, :client_request_opts])
    }
  end

  defp log_event(level, message, _ts, metadata, state) do
    metadata = take_metadata(metadata, state.metadata)
    message = Formatter.format_event(message, level, metadata)

    with {:error, reason} <- Sender.send_message(message, state.sender_opts) do
      IO.warn("#{__MODULE__} failed to send message: #{inspect(reason)}")
    end
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    for key <- Enum.reverse(keys), reduce: [] do
      acc ->
        case Keyword.fetch(metadata, key) do
          {:ok, val} -> [{key, val} | acc]
          :error -> acc
        end
    end
  end
end
