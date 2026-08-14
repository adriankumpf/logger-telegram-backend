defmodule LoggerTelegramBackend.ConfigTest do
  use ExUnit.Case, async: true

  alias LoggerTelegramBackend.Config
  alias LoggerTelegramBackend.ConfigError
  alias LoggerTelegramBackend.HTTPClient
  alias LoggerTelegramBackend.Token

  @required [token: "$token", chat_id: "$chat_id"]

  describe "new/1" do
    test "applies the defaults" do
      assert %Config{
               level: nil,
               metadata: [:line, :function, :module, :application, :file],
               metadata_filter: [],
               client: HTTPClient.Finch,
               client_pool_opts: [],
               client_request_opts: []
             } = Config.new([])
    end

    test "ignores unknown options" do
      assert Config.new(nope: true) == Config.new([])
    end

    test "treats a nil value as unset" do
      assert Config.new(metadata: nil, metadata_filter: nil, client: nil) == Config.new([])
    end

    test "wraps the token" do
      assert %Config{token: %Token{}} = Config.new(@required)
    end

    test "normalizes the deprecated :warn level" do
      assert Config.new(level: :warn).level == :warning
    end
  end

  describe "validate/1" do
    test "accepts a complete configuration" do
      assert :ok = @required |> Config.new() |> Config.validate()
    end

    test "accepts every level Logger knows, plus nil and the deprecated :warn" do
      for level <- [nil, :warn | Logger.levels()] do
        config = Config.new(@required ++ [level: level])
        assert :ok = Config.validate(config), "rejected #{inspect(level)}"
      end
    end

    test "rejects a missing or non-string :token" do
      assert {:error, %ConfigError{message: message}} =
               [chat_id: "$chat_id"] |> Config.new() |> Config.validate()

      assert message =~ ":token is missing"

      assert {:error, %ConfigError{}} =
               [token: :not_a_string, chat_id: "$chat_id"] |> Config.new() |> Config.validate()
    end

    test "rejects a missing :chat_id" do
      assert {:error, %ConfigError{message: message}} =
               [token: "$token"] |> Config.new() |> Config.validate()

      assert message =~ ":chat_id is missing"
    end

    test "rejects an unknown :level" do
      assert {:error, %ConfigError{message: message}} =
               (@required ++ [level: :bogus]) |> Config.new() |> Config.validate()

      assert message =~ "invalid :level :bogus"
    end

    test "rejects invalid :metadata" do
      for metadata <- ["all", ["line"], %{}] do
        assert {:error, %ConfigError{message: message}} =
                 (@required ++ [metadata: metadata]) |> Config.new() |> Config.validate()

        assert message =~ "invalid :metadata"
      end
    end

    test "rejects invalid :metadata_filter" do
      for filter <- [%{}, ["user"], :user] do
        assert {:error, %ConfigError{message: message}} =
                 (@required ++ [metadata_filter: filter]) |> Config.new() |> Config.validate()

        assert message =~ "invalid :metadata_filter"
      end
    end

    test "the error explains how to configure the backend" do
      assert {:error, %ConfigError{message: message}} = [] |> Config.new() |> Config.validate()

      assert message =~ "config :logger, LoggerTelegramBackend"
    end
  end
end
