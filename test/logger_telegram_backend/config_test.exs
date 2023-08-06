defmodule LoggerTelegramBackend.ConfigTest do
  use ExUnit.Case, async: false

  alias LoggerTelegramBackend.Config
  alias LoggerTelegramBackend.HTTPClient

  setup do
    on_exit(fn ->
      Application.delete_env(:logger, LoggerTelegramBackend)
    end)
  end

  describe "client/0" do
    test "selects finch over hackney" do
      assert Config.client() == HTTPClient.Finch
      assert Application.get_env(:logger, LoggerTelegramBackend)[:client] == HTTPClient.Finch
    end

    test "read the application config" do
      Application.put_env(:logger, LoggerTelegramBackend, client: MyClient)
      assert Config.client() == MyClient
    end
  end

  describe "client_pool_opts/0" do
    test "read the application config" do
      Application.put_env(:logger, LoggerTelegramBackend, client_pool_opts: [foo: :bar])
      assert Config.client_pool_opts() == [foo: :bar]
    end
  end

  describe "client_request_opts/0" do
    test "read the application config" do
      Application.put_env(:logger, LoggerTelegramBackend, client_request_opts: [foo: :bar])
      assert Config.client_request_opts() == [foo: :bar]
    end
  end
end
