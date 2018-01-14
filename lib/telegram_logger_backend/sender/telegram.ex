defmodule LoggerTelegramBackend.Sender.Telegram do
  @moduledoc false

  @base_url "https://api.telegram.org"
  @default_timeout :timer.seconds(5)

  def send_message(text, token, chat_id) do
    request(
      "sendMessage",
      token,
      text: text,
      chat_id: chat_id,
      parse_mode: "HTML"
    )
  end

  defp request(method, token, options) do
    method
    |> build_url(token)
    |> HTTPoison.post(build_request(options), [], recv_timeout: @default_timeout)
    |> process_response()
  end

  defp build_url(method, token), do: "#{@base_url}/bot#{token}/#{method}"

  defp process_response(response) do
    case decode_response(response) do
      {:ok, _} -> :ok
      %{ok: false, description: description} -> {:error, %{reason: description}}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, %{reason: reason}}
    end
  end

  defp decode_response(response) do
    with {:ok, %HTTPoison.Response{body: body}} <- response,
         %{result: result} <- Poison.decode!(body, keys: :atoms) do
      {:ok, result}
    end
  end

  defp build_request(params) when is_list(params) do
    data =
      params
      |> Enum.filter(fn {_, v} -> v end)
      |> Enum.map(fn {k, v} -> {k, to_string(v)} end)

    {:form, data}
  end
end
