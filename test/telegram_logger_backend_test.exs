defmodule TelegramLoggerBackendTest do
  use ExUnit.Case
  doctest TelegramLoggerBackend

  test "greets the world" do
    assert TelegramLoggerBackend.hello() == :world
  end
end
