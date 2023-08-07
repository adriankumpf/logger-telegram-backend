defmodule LoggerTelegramBackend do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Adds the LoggerTelegramBackend backend.

  ## Options

    * `:flush` - when `true`, guarantees all messages currently sent
      to `Logger` are processed before the backend is added

  """
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

  """
  @spec detach(keyword) :: :ok | {:error, term}
  def detach(opts \\ [])

  case System.version() >= "1.15.0" do
    true -> def detach(opts), do: LoggerBackends.remove(__MODULE__, opts)
    false -> def detach(opts), do: Logger.remove_backend(__MODULE__, opts)
  end

  @doc """
  Applies runtime configuration.

  See the module doc for more information.
  """
  @spec configure(keyword) :: term
  case System.version() >= "1.15.0" do
    true -> def configure(opts), do: LoggerBackends.configure(__MODULE__, opts)
    false -> def configure(opts), do: Logger.configure_backend(__MODULE__, opts)
  end

  @behaviour :gen_event

  alias LoggerTelegramBackend.Formatter

  @default_sender LoggerTelegramBackend.Sender
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
  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, message, timestamp, metadata}}, state) do
    if meet_level?(level, state.level) and metadata_matches?(metadata, state.metadata_filter) do
      log_event(level, message, timestamp, metadata, state)
    end

    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_info(_message, state) do
    {:ok, state}
  end

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
    metadata = config[:metadata] || @default_metadata

    sender = get_sender(config)
    sender_opts = Keyword.take(config, [:token, :chat_id, :client_request_opts])

    %{
      level: config[:level],
      metadata: configure_metadata(metadata),
      metadata_filter: config[:metadata_filter],
      send_message: &sender.send_message(&1, sender_opts)
    }
  end

  case Mix.env() do
    :test -> defp get_sender(opts), do: opts[:sender] || @default_sender
    _prod -> defp get_sender(_opts), do: @default_sender
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp log_event(level, message, _ts, metadata, state) do
    metadata = take_metadata(metadata, state.metadata)
    message = Formatter.format_event(message, level, metadata)

    with {:error, reason} <- state.send_message.(message) do
      IO.warn("#{__MODULE__} failed to send message: #{inspect(reason)}")
    end
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
  end
end
