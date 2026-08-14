defmodule LoggerTelegramBackend do
  @moduledoc """
  A logger backend for [Telegram](https://telegram.org/).

  ## Usage

  In your `c:Application.start/2` callback, add the `LoggerTelegramBackend`:

      @impl true
      def start(_type, _args) do
        {:ok, _} = LoggerTelegramBackend.attach()

        # ...
      end

  Add the following to your configuration:

      config :logger, LoggerTelegramBackend,
        chat_id: "your_chat_id",
        token: "yout_bot_token"

  To create a Telegram bot, see the next section.

  ### Creating a Telegram bot

  To create a Telegram bot, follow the instructions
  [here](https://core.telegram.org/bots/features#creating-a-new-bot)  and get the `token` for the
  bot.

  Then send a message to the bot and get your `chat_id`:

   ```bash
   TOKEN="..."
   curl https://api.telegram.org/bot$TOKEN/getUpdates
   ```

  ## Configuration

  You can configure LoggerTelegramBackend through the application environment. Configure the
  following options under the `LoggerTelegramBackend` key of the `:logger` application. For example,
  you can do this in `config/runtime.exs`:

      # config/runtime.exs
      config :logger, LoggerTelegramBackend,
        chat_id: System.fetch_env!("TELEGRAM_CHAT_ID"),
        token: System.fetch_env!("TELEGRAM_TOKEN"),
        level: :warning,
        # ...

  The basic configuration options are:

  - `:level` (`t:Logger.level/0`) - the level to be logged by this backend. Note that messages are
  first filtered by the general `:level` configuration for the `:logger` application. Defaults to
  `nil` (all levels are logged).

  - `:metadata` (list of `t:atom/0` or `:all`) - the metadata to be included in the message. `:all`
  will get all metadata. Defaults to`[:line, :function, :module, :application, :file]`.

  - `:metadata_filter` (`t:keyword/0`, may also include `t:atom/0`) - the key-value pairs or keys
  that is must be present in the metadata for a message to be sent. Defaults to `[]`. See the
  [*Filtering Messages* section](#filtering-messages) below.

  To customize the behaviour of the HTTP client used by LoggerTelegramBackend, you can use these
  options:

  - `:client` (`t:module/0`) - A module that implements the `LoggerTelegramBackend.HTTPClient`
  behaviour. Defaults to `LoggerTelegramBackend.HTTPClient.Finch` (requires `:finch`).

  - `:client_pool_opts` (`t:keyword/0`) - Options to configure the HTTP client pool. See
  `Finch.start_link/1`. Defaults to `[]`.

  - `:client_request_opts` (`t:keyword/0`) - Options passed to the
  `c:LoggerTelegramBackend.HTTPClient.request/5` callback. See `Finch.request/3`. Defaults to `[]`.

  ## Filtering messages

  If you would like to prevent LoggerTelegramBackend from sending certain messages, you can
  use the `:metadata_filter` configuration option. It must be configured to be a list of key-value
  pairs or keys.

  ### Examples

  - `metadata_filter: [application: :core]` - The metadata must contain `application: :core`
  - `metadata_filter: [:user]` - The metadata must contain the key `:user`, but it can be set to any value
  - `metadata_filter: [{:application, :core}, :user]` - The metadata must contain `application:
  :core` **AND** must include the key `:user`

  ## Using a proxy

  An HTTP proxy can be configured via the `:client_pool_opts` option:

      config :logger, LoggerTelegramBackend,
        # ...
        client_pool_opts: [conn_opts: [proxy: {:http, "127.0.0.1", 8888, []}]]

  See the [Pool Configuration
  Options](https://hexdocs.pm/finch/Finch.html#start_link/1-pool-configuration-options) for further
  information.
  """

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

  def handle_event({level, _gl, {Logger, message, timestamp, metadata}}, state) do
    level = event_level(metadata, level)

    if meet_level?(level, state.level) and metadata_matches?(metadata, state.metadata_filter) do
      log_event(level, message, timestamp, metadata, state)
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

  defp log_event(level, message, _ts, metadata, state) do
    metadata = take_metadata(metadata, state.metadata)
    message = Formatter.format_event(message, level, metadata)

    with {:error, reason} <- Sender.send_message(message, state) do
      report_failure(reason, state.token)
    end
  end

  # Reported to stderr rather than through `Logger`, which would feed straight back into this
  # backend.
  defp report_failure(reason, token) do
    message = "#{__MODULE__} failed to send message: #{inspect(reason)}"
    IO.puts(:stderr, Token.redact(message, token))
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    Enum.flat_map(keys, fn key ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val}]
        :error -> []
      end
    end)
  end
end
