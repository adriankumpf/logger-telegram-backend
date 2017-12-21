defmodule SenderTelegramTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias TelegramLoggerBackend.Sender.Telegram

  setup_all do
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
      assert Telegram.send_message("tach", "$token", "$chatId") == :ok
    end
  end
end
