defmodule LoggerTelegramBackend.HTMLTest do
  use ExUnit.Case, async: true

  alias LoggerTelegramBackend.HTML

  test "escapes HTML" do
    input = "<foo> && #1 || '\"'"

    assert HTML.escape(input) == "&lt;foo&gt; &amp;&amp; #1 || '\"'"
  end
end
