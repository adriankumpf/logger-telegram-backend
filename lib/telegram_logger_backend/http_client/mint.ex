defmodule LoggerTelegramBackend.HTTPClient.Mint do
  @moduledoc false

  @behaviour LoggerTelegramBackend.HTTPClient

  if Code.ensure_loaded?(Mint.HTTP) do
    alias Mint.HTTP

    @impl true
    def post(url, data, opts) do
      %URI{host: host, scheme: scheme, port: port, path: path} = URI.parse(url)

      headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
      body = URI.encode_query(data)

      with {:ok, conn} <- HTTP.connect(String.to_atom(scheme), host, port, opts),
           {:ok, conn, _req_ref} <- HTTP.request(conn, "POST", path || "/", headers, body),
           {:ok, conn, res = %{status: status}} <- stream_response(conn, opts),
           {:ok, _conn} <- HTTP.close(conn) do
        case status do
          200 -> :ok
          status -> {:error, {:bad_status_code, status, Map.get(res, :data)}}
        end
      end
    end

    defp stream_response(conn, opts, response \\ %{}) do
      receive do
        msg ->
          case HTTP.stream(conn, msg) do
            {:ok, conn, stream} ->
              response =
                Enum.reduce(stream, response, fn
                  {:status, _req_ref, code}, acc ->
                    Map.put(acc, :status, code)

                  {:headers, _req_ref, headers}, acc ->
                    Map.put(acc, :headers, Map.get(acc, :headers, []) ++ headers)

                  {:data, _req_ref, data}, acc ->
                    Map.put(acc, :data, Map.get(acc, :data, "") <> data)

                  {:done, _req_ref}, acc ->
                    Map.put(acc, :done, true)

                  {:error, _req_ref, reason}, acc ->
                    Map.put(acc, :error, reason)

                  _, acc ->
                    acc
                end)

              cond do
                Map.has_key?(response, :error) ->
                  {:error, Map.get(response, :error)}

                Map.has_key?(response, :done) ->
                  {:ok, conn, Map.drop(response, [:done])}

                true ->
                  stream_response(conn, opts, response)
              end

            {:error, _conn, error, _res} ->
              {:error, "Encounter Mint error #{inspect(error)}"}

            :unknown ->
              {:error, "Encounter unknown error"}
          end
      after
        Keyword.get(opts, :timeout, 15_000) ->
          {:error, "Response timeout"}
      end
    end
  else
    @message """
    missing :mint dependency

    LoggerTelegramBackend requires a HTTP client.

    In order to use the built-in adapter based on Mint HTTP client, add the
    following to your mix.exs dependencies list:

        {:mint, "~> 0.4"},
        {:castore, "~> 0.1"}

    See README for more information.
    """

    @impl true
    def post(_url, _headers, _options) do
      raise @message
    end
  end
end
