defmodule LoggerTelegramBackend.Config do
  @moduledoc false

  alias LoggerTelegramBackend.HTTPClient

  def client, do: get_config(:client) || get_default_client()
  def client_pool_opts, do: get_config(:client_pool_opts, [])
  def client_request_opts, do: get_config(:client_request_opts, [])

  defp get_default_client do
    cond do
      Code.ensure_loaded?(Finch) ->
        start_application!(:finch)
        persist_client(HTTPClient.Finch)

      Code.ensure_loaded?(:hackney) ->
        start_application!(:hackney)
        persist_client(HTTPClient.Hackney)

      true ->
        raise """
        LoggerTelegramBackend failed to start. Add either :finch or :hackney to your dependencies \
        to fix this, or configure a different HTTP client.
        """
    end
  end

  defp start_application!(application) do
    with {:error, reason} <- Application.ensure_all_started(application) do
      raise "failed to start the #{inspect(application)} application: #{inspect(reason)}"
    end
  end

  defp persist_client(client_module) do
    config =
      Application.get_env(:logger, LoggerTelegramBackend, [])
      |> Keyword.put(:client, client_module)

    :ok = Application.put_env(:logger, LoggerTelegramBackend, config)

    client_module
  end

  defp get_config(key, default \\ nil) do
    config = Application.get_env(:logger, LoggerTelegramBackend, [])
    Keyword.get(config, key, default)
  end
end
