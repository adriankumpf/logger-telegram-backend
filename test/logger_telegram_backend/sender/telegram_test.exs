for name <- [Finch, Hackney] do
  module = Module.concat([LoggerTelegramBackend.Sender.Telegram, name, Test])
  client = Module.concat(LoggerTelegramBackend.HTTPClient, name)
  adapter = Module.concat(ExVCR.Adapter, name)

  quote do
    defmodule unquote(module) do
      use ExUnit.Case, async: false
      use ExVCR.Mock, adapter: unquote(adapter)

      setup do
        Application.put_env(:logger, LoggerTelegramBackend, client: unquote(client))

        on_exit(fn ->
          Application.delete_env(:logger, LoggerTelegramBackend)
        end)

        ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
        ExVCR.Config.filter_sensitive_data("bot[^/]+/", "bot<TOKEN>/")
        ExVCR.Config.filter_sensitive_data("id\":\\d+", "id\":666")
        ExVCR.Config.filter_sensitive_data("id=\\d+", "id=666")
        ExVCR.Config.filter_sensitive_data("_id=@w+", "_id=@group")
        ExVCR.Config.filter_sensitive_data("name\":\"\\w+", "name\":\"$name")
        :ok
      end

      test "send_message" do
        use_cassette "send_message" do
          assert :ok =
                   LoggerTelegramBackend.Sender.Telegram.send_message("tach",
                     token: "$token",
                     chat_id: "$chatId"
                   )
        end
      end
    end
  end
  |> Code.eval_quoted()
end
