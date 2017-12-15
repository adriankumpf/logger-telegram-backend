defmodule SenderTelegramTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias TelegramLoggerBackend.Sender.Telegram

  setup_all do
    unless Application.get_env(:logger, :telegram) do
      Application.put_env(:logger, :telegram, [
        chat_id: 1111111,
        token: "TOKEN"
      ])
    end
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
      assert Telegram.send_message("tach") == :ok
    end
  end
end
