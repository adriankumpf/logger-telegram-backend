defmodule TelegramLoggerBackend do
  @moduledoc """
  A logger backend for posting messages to [Telegram]( https://telegram.org/).

  ## Installation

  Add `:telegram_logger_backend` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:telegram_logger_backend, "~> 0.3.0"}]
  end
  ```

  ## Configuration

  Add `TelegramLoggerBackend` to the `:backends` configuration. Then add your
  telegram `chat_id` and bot `token`:

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

  In addition, the following options are available:

    * `:level` - the level to be logged by this backend (either `:debug`,
      `:info`, `:warn` or `:error`). Note that messages are filtered by the
      general `:level` configuration for the `:logger` application first. If not
      explicitly configured all levels are logged.
    * `:metadata` - the metadata to be included in the telegram message. Defaults
      to  `[:line, :function, :module, :application, :file]`. Setting `:metadata`
      to `:all` gets all metadata.
    * `:metadata_filter` - the metadata which is required in order for a message
      to be logged. Example: `metadata_filter: [application: :ui]`.


  #### Example

  ```elixir
  config :logger, :telegram,
    chat_id: "$chatId",
    token: "$botToken",
    level: :info,
    metadata: :all
    metadata_filter: [application: :ui]
  ```

  ### Multiple logger handlers

  Like the
  [LoggerFileBackend](https://github.com/onkel-dirtus/logger_file_backend)
  multiple logger handlers may be configured, each with different `:chat_id`s,
  `:level`s etc. Each handler has to be configured as a logger backend:

  ```elixir
  config :logger,
    backends: [
      {TelegramLoggerBackend, :telegram_filter},
      {TelegramLoggerBackend, :telegram_level},
      :console
    ]

  config :logger, :telegram_filter,
    chat_id: "$chatId",
    token: "$botToken",
    metadata_filter: [application: :ui],
    metadata: [:line, :function, :module, :pid]

  config :logger, :telegram_level,
    chat_id: "$chatId",
    token: "$botToken",
    level: :warn,
  ```
  """

  @behaviour :gen_event

  defstruct [:name, :level, :metadata, :metadata_filter, :sender, :sender_args]

  alias TelegramLoggerBackend.Sender.Telegram
  alias TelegramLoggerBackend.Manager

  @default_name :telegram
  @default_sender {Telegram, [:token, :chat_id]}
  @default_metadata [:line, :function, :module, :application, :file]

  # Callbacks

  def init(__MODULE__), do: init({__MODULE__, @default_name})

  def init({__MODULE__, name}) when is_atom(name) do
    state =
      Application.get_env(:logger, name)
      |> initialize(%__MODULE__{})

    {:ok, state}
  end

  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event(
        {level, _gl, {Logger, msg, ts, md}},
        %{level: log_lvl, metadata_filter: filter} = state
      ) do
    if meet_level?(level, log_lvl) and metadata_matches?(md, filter) do
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
    initialize(config, state)
  end

  defp initialize(config, state) do
    {sender, sender_args} = Keyword.get(config, :sender, @default_sender)

    level = Keyword.get(config, :level)
    metadata = Keyword.get(config, :metadata, @default_metadata)
    metadata_filter = Keyword.get(config, :metadata_filter)

    %{
      state
      | sender: sender,
        sender_args: Enum.map(sender_args, &Keyword.get(config, &1)),
        metadata: configure_metadata(metadata),
        level: level,
        metadata_filter: metadata_filter
    }
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp log_event(lvl, msg, ts, md, %{sender: sender, sender_args: sender_args, metadata: keys}) do
    event = %{
      level: lvl,
      message: msg,
      metadata: take_metadata(md, keys),
      timestamp: ts
    }

    Manager.add_event({sender, sender_args, event})
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
