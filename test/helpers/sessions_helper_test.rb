require "test_helper"

class SessionsHelperTest < ActionView::TestCase
  test "summarises common user agents" do
    assert_equal "Chrome on macOS", short_user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36")
    assert_equal "Safari on iOS", short_user_agent("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1")
    assert_equal "Edge on Windows", short_user_agent("Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 Chrome/120.0 Safari/537.36 Edg/120.0")
    assert_equal "Firefox on Linux", short_user_agent("Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0")
  end

  test "falls back for blank or unknown user agents" do
    assert_equal "Unknown device", short_user_agent(nil)
    assert_equal "Unknown device", short_user_agent("")
    assert_equal "curl/8.4.0", short_user_agent("curl/8.4.0")
    assert_operator short_user_agent("x" * 200).length, :<=, 60
  end
end
