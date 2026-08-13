defmodule LoggerTelegramBackend.ConfigTest do
  use ExUnit.Case, async: false

  alias LoggerTelegramBackend.Config
  alias LoggerTelegramBackend.HTTPClient

  setup do
    on_exit(fn ->
      Application.delete_env(:logger, LoggerTelegramBackend)
    end)
  end

  describe "client/1" do
    test "defaults to finch" do
      assert Config.client([]) == HTTPClient.Finch
    end

    test "reads the application config" do
      Application.put_env(:logger, LoggerTelegramBackend, client: MyClient)
      assert Config.client(Config.all()) == MyClient
    end
  end

  describe "client_pool_opts/1" do
    test "defaults to an empty list" do
      assert Config.client_pool_opts([]) == []
    end

    test "reads the application config" do
      Application.put_env(:logger, LoggerTelegramBackend, client_pool_opts: [foo: :bar])
      assert Config.client_pool_opts(Config.all()) == [foo: :bar]
    end
  end

  describe "all/0" do
    test "defaults to an empty list when unset" do
      assert Config.all() == []
    end
  end
end
