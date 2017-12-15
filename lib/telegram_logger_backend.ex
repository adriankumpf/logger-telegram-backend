defmodule TelegramLoggerBackend do
  @moduledoc false

  @behaviour :gen_event

  defstruct level: nil, metadata: nil, chat_id: nil

  @default_metadata [:line, :function, :module, :application, :file]

  def init(__MODULE__) do
    config = Application.get_env(:logger, :telegram)
    {:ok, init(config, %__MODULE__{})}
  end

  def init({__MODULE__, opts}) when is_list(opts) do
    config = Keyword.merge(Application.get_env(:logger, :telegram), opts)
    {:ok, init(config, %__MODULE__{})}
  end

  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: log_level} = state) do
    if meet_level?(level, log_level) do
      :ok = log_event(level, msg, ts, md, state)
    end

    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def handle_info(_message, state) do
    {:ok, state}
  end

  ## Helpers

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min), do: Logger.compare_levels(lvl, min) != :lt

  defp configure(options, state) do
    config = Keyword.merge(Application.get_env(:logger, :telegram), options)
    Application.put_env(:logger, :telegram, config)
    init(config, state)
  end

  defp init(config, state) do
    level = Keyword.get(config, :level)
    metadata = Keyword.get(config, :metadata, @default_metadata) |> configure_metadata()

    %{state | metadata: metadata, level: level}
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp log_event(level, msg, ts, md, %{metadata: keys}) do
    event = %{
      level: level,
      message: msg,
      metadata: take_metadata(md, keys),
      timestamp: ts
    }

    TelegramLoggerBackend.Logger.add_event(event)
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
