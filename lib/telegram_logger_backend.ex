defmodule LoggerTelegramBackend do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @behaviour :gen_event

  defmodule State do
    defstruct [:name, :level, :metadata, :metadata_filter, :sender, :sender_args]
  end

  alias LoggerTelegramBackend.{Formatter, Telegram}

  @default_name :telegram
  @default_sender {Telegram, [:token, :chat_id, :proxy]}
  @default_metadata [:line, :function, :module, :application, :file]

  @impl :gen_event
  def init(__MODULE__) do
    init({__MODULE__, @default_name})
  end

  def init({__MODULE__, name}) when is_atom(name) do
    state =
      Application.get_env(:logger, name)
      |> initialize(%State{})

    {:ok, state}
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
      :ok = log_event(level, message, timestamp, metadata, state)
    end

    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_info(_message, state) do
    {:ok, state}
  end

  ## Private

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min), do: Logger.compare_levels(lvl, min) != :lt

  defp metadata_matches?(_metadata, nil), do: true
  defp metadata_matches?(_metadata, []), do: true

  defp metadata_matches?(metadata, [{k, v} | rest]) do
    case Keyword.fetch(metadata, k) do
      {:ok, ^v} -> metadata_matches?(metadata, rest)
      _ -> false
    end
  end

  defp configure(options, %State{} = state) do
    config = Keyword.merge(Application.get_env(:logger, :telegram), options)
    Application.put_env(:logger, :telegram, config)
    initialize(config, state)
  end

  defp initialize(config, %State{} = state) do
    {sender, sender_args} = Keyword.get(config, :sender, @default_sender)

    level = Keyword.get(config, :level)
    metadata = Keyword.get(config, :metadata, @default_metadata)
    metadata_filter = Keyword.get(config, :metadata_filter)

    %State{
      state
      | sender: sender,
        sender_args: Keyword.take(config, sender_args),
        metadata: configure_metadata(metadata),
        level: level,
        metadata_filter: metadata_filter
    }
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp log_event(lvl, msg, _ts, md, %State{sender: sender, sender_args: args, metadata: keys}) do
    metadata = take_metadata(md, keys)

    Formatter.format_event(msg, lvl, metadata)
    |> sender.send_message(args)
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
