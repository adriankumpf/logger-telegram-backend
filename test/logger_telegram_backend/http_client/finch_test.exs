defmodule LoggerTelegramBackend.HTTPClient.FinchTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  alias LoggerTelegramBackend.Config
  alias LoggerTelegramBackend.Sender

  setup do
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
    ExVCR.Config.filter_sensitive_data("bot[^/]+/", "bot<TOKEN>/")
    ExVCR.Config.filter_sensitive_data("id\":\\d+", "id\":666")
    ExVCR.Config.filter_sensitive_data("id=\\d+", "id=666")
    ExVCR.Config.filter_sensitive_data("_id=@\\w+", "_id=@group")
    ExVCR.Config.filter_sensitive_data("name\":\"\\w+", "name\":\"$name")
    :ok
  end

  test "sends message" do
    use_cassette "send_message" do
      config = Config.new(token: "$token", chat_id: "$chatId")

      assert :ok = Sender.send_message("tach", config)
    end
  end
end
