defmodule TelegramLoggerBackend do
  @moduledoc """
  A logger backend for posting messages to [Telegram]( https://telegram.org/).

  ## Installation

  Add `:telegram_logger_backend` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:telegram_logger_backend, "~> 0.2.0"}]
  end
  ```

  Then add `TelegramLoggerBackend` to the `:backends` configuration and add the
  telegram credentials:

  ```elixir
  config :logger, backends: [TelegramLoggerBackend, :console]

  config :logger, :telegram,
    chat_id: "$chatId",
    token: "$botToken"
  ```

  The logger configuration is read at runtime from the application environment so
  that you can provide it via
  [distillerys](https://github.com/bitwalker/distillery) dynamic configuration
  with environment variables.

  ### Options

    * `:level` - the level to be logged by this backend (either `:debug`,
      `:info`, `:warn` or `:error`). Note that messages are filtered by the
      general `:level` configuration for the `:logger` application first. If not
      explicitly configured all levels are logged.
    * `:metadata` - the metadata to be included in the telegram message. Defaults
      to  `[:line, :function, :module, :application, :file]`. Setting `:metadata`
      to `:all` prints all metadata.
    * `:metadata_filter` - the metadata which is required in order for a message
      to be logged. Example: `metadata_filter: [application: :ui]`.


  #### Example

  ```elixir
  config :logger, :telegram,
    chat_id: "$chatId",
    token: "$botToken",
    level: :info,
    metadata: :all
    metadata_filter: [application: ui]
  ```
  """

  @behaviour :gen_event

  defstruct [:level, :metadata, :metadata_filter, :sender]

  alias TelegramLoggerBackend.Sender.Telegram
  alias TelegramLoggerBackend.Manager

  @default_metadata [:line, :function, :module, :application, :file]
  @default_sender Telegram

  # Callbacks

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

  def handle_event(
        {level, _gl, {Logger, msg, ts, md}},
        %{level: log_level, metadata_filter: metadata_filter} = state
      ) do
    if meet_level?(level, log_level) and metadata_matches?(md, metadata_filter) do
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

  defp metadata_matches?(_metadata, nil), do: true
  defp metadata_matches?(_metadata, []), do: true

  defp metadata_matches?(metadata, [{k, v} | rest]) do
    case Keyword.fetch(metadata, k) do
      {:ok, ^v} -> metadata_matches?(metadata, rest)
      _ -> false
    end
  end

  defp configure(options, state) do
    config = Keyword.merge(Application.get_env(:logger, :telegram), options)
    Application.put_env(:logger, :telegram, config)
    init(config, state)
  end

  defp init(config, state) do
    level = Keyword.get(config, :level)
    metadata = Keyword.get(config, :metadata, @default_metadata) |> configure_metadata()
    metadata_filter = Keyword.get(config, :metadata_filter)
    sender = Keyword.get(config, :sender, @default_sender)

    %{state | metadata: metadata, level: level, sender: sender, metadata_filter: metadata_filter}
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp log_event(level, msg, ts, md, %{metadata: keys, sender: sender}) do
    event = %{
      level: level,
      message: msg,
      metadata: take_metadata(md, keys),
      timestamp: ts
    }

    Manager.add_event({sender, event})
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
