defmodule LoggerTelegramBackend do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @behaviour :gen_event

  defmodule State do
    @moduledoc false
    defstruct [:level, :metadata, :metadata_filter, :send_message]
  end

  alias LoggerTelegramBackend.{Formatter, Sender}

  @default_sender {Sender.Telegram, [:token, :chat_id]}
  @default_metadata [:line, :function, :module, :application, :file]

  @impl :gen_event
  def init(__MODULE__) do
    config = Application.get_env(:logger, __MODULE__, [])
    {:ok, initialize(config, %State{})}
  end

  @impl :gen_event
  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
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

  defp configure(options, %State{} = state) do
    config = Keyword.merge(Application.get_env(:logger, __MODULE__), options)
    Application.put_env(:logger, __MODULE__, config)
    initialize(config, state)
  end

  defp initialize(config, %State{} = state) do
    metadata = config[:metadata] || @default_metadata
    {sender, sender_opts} = config[:sender] || @default_sender
    sender_opts = Keyword.take(config, sender_opts)

    %State{
      state
      | level: config[:level],
        metadata: configure_metadata(metadata),
        metadata_filter: config[:metadata_filter],
        send_message: &sender.send_message(&1, sender_opts)
    }
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp log_event(level, message, _ts, metadata, %State{} = state) do
    metadata = take_metadata(metadata, state.metadata)

    message
    |> Formatter.format_event(level, metadata)
    |> state.send_message.()
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
