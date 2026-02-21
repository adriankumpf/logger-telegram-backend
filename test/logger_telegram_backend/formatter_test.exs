defmodule LoggerTelegramBackend.FormatterTest do
  use ExUnit.Case, async: true

  alias LoggerTelegramBackend.Formatter

  describe "format_event/3" do
    test "includes level tag, message, and metadata" do
      result = Formatter.format_event("hello", :info, module: MyApp)

      assert result == """
             <b>[info]</b> <b>hello</b>
             <pre>Module: MyApp</pre>\
             """
    end

    test "formats with empty metadata" do
      result = Formatter.format_event("hello", :error, [])

      assert result == "<b>[error]</b> <b>hello</b>"
    end

    test "escapes HTML in message" do
      result = Formatter.format_event("<script>alert('xss')</script>", :warn, [])

      assert result == "<b>[warn]</b> <b>&lt;script&gt;alert('xss')&lt;/script&gt;</b>"
    end

    test "escapes HTML in metadata values" do
      result = Formatter.format_event("msg", :info, user: "<b>bad</b>")

      assert result == """
             <b>[info]</b> <b>msg</b>
             <pre>User: "&lt;b&gt;bad&lt;/b&gt;"</pre>\
             """
    end

    test "highlights first line as title in multi-line messages" do
      result = Formatter.format_event("title\ndetails\nmore", :info, [])

      assert result == """
             <b>[info]</b> <b>title</b>
             details
             more\
             """
    end

    test "wraps single-line message in bold" do
      result = Formatter.format_event("single line", :debug, [])

      assert result == "<b>[debug]</b> <b>single line</b>"
    end

    test "trims leading and trailing whitespace from message" do
      result = Formatter.format_event("  hello  \n", :info, [])

      assert result == "<b>[info]</b> <b>hello</b>"
    end

    test "accepts iolist message" do
      result = Formatter.format_event(["hello", ?\s, "world"], :info, [])

      assert result == "<b>[info]</b> <b>hello world</b>"
    end

    test "joins multiple metadata keys with newlines" do
      result = Formatter.format_event("msg", :info, module: Foo, function: "bar/1")

      assert result == """
             <b>[info]</b> <b>msg</b>
             <pre>Module: Foo
             Function: "bar/1"</pre>\
             """
    end
  end

  describe "truncation" do
    test "display length never exceeds 4096" do
      result = Formatter.format_event(String.duplicate("A", 9999), :info, [])

      assert display_length(result) <= 4096
      assert result =~ "…"
    end

    test "display length respects limit with metadata" do
      result =
        Formatter.format_event(String.duplicate("A", 9999), :info,
          module: SomeModule,
          function: "some_function/2"
        )

      assert display_length(result) <= 4096
      assert result =~ "…"
    end

    test "handles multibyte and emoji characters within display limit" do
      for grapheme <- ["é", "💜", "🇺🇸"] do
        result = Formatter.format_event(String.duplicate(grapheme, 9999), :info, [])

        assert display_length(result) <= 4096
        assert result =~ "…"
        assert String.valid?(result)
      end
    end

    test "escapes HTML entities after truncation" do
      result = Formatter.format_event(String.duplicate("&", 9999), :info, [])

      assert display_length(result) <= 4096
      assert result =~ "&amp;"
      assert result =~ "…"
    end

    test "short messages are not truncated" do
      result = Formatter.format_event("short", :info, [])

      assert result == "<b>[info]</b> <b>short</b>"
      refute result =~ "…"
    end

    test "truncates both message and metadata when both are oversized" do
      result =
        Formatter.format_event(String.duplicate("M", 5000), :info,
          big: String.duplicate("x", 5000)
        )

      assert display_length(result) <= 4096
      assert String.contains?(result, "…")
      assert result =~ "<pre>"
      assert result =~ "Big:"
    end

    test "metadata overflow does not starve the message" do
      huge_metadata = String.duplicate("x", 5000)
      message = String.duplicate("m", 100)
      result = Formatter.format_event(message, :info, big: huge_metadata)

      # The message should get at least @reserved_for_message characters (50),
      # not be squeezed out by oversized metadata.
      assert display_length(result) <= 4096
      assert result =~ String.duplicate("m", 49)
      assert result =~ "…"
    end
  end

  describe "display_length/1 helper" do
    test "does not double-decode entities" do
      # "&amp;lt;" displays as "&lt;" (4 chars), not "<" (1 char)
      assert display_length("&amp;lt;") == 4
      assert display_length("&amp;gt;") == 4
      assert display_length("&amp;amp;") == 5
    end
  end

  defp display_length(html), do: LoggerTelegramBackend.TestHelpers.display_length(html)
end
