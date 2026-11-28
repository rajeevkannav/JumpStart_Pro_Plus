module SessionsHelper
  BROWSERS = [
    [ /Edg(e|A|iOS)?\//, "Edge" ],
    [ /OPR\/|Opera/, "Opera" ],
    [ /Firefox\/|FxiOS\//, "Firefox" ],
    [ /Chrome\/|CriOS\//, "Chrome" ],
    [ /Safari\//, "Safari" ]
  ].freeze

  PLATFORMS = [
    [ /iPhone|iPad|iPod/, "iOS" ],
    [ /Android/, "Android" ],
    [ /Windows/, "Windows" ],
    [ /Mac OS X|Macintosh/, "macOS" ],
    [ /CrOS/, "ChromeOS" ],
    [ /Linux/, "Linux" ]
  ].freeze

  # "Mozilla/5.0 (Macintosh; ...) Chrome/120 Safari/537" => "Chrome on macOS".
  # Falls back to the raw string, truncated, when nothing is recognised.
  def short_user_agent(user_agent)
    return "Unknown device" if user_agent.blank?

    browser = BROWSERS.find { |pattern, _| user_agent.match?(pattern) }&.last
    platform = PLATFORMS.find { |pattern, _| user_agent.match?(pattern) }&.last

    if browser && platform
      "#{browser} on #{platform}"
    else
      browser || platform || user_agent.truncate(60)
    end
  end
end
