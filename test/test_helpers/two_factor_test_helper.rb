# Helpers for driving TOTP two-factor authentication in tests.
module TwoFactorTestHelper
  def totp_code(secret, at: Time.current)
    ROTP::TOTP.new(secret).at(at)
  end

  # A 6-digit code that is not valid for +secret+ right now (nor within
  # the allowed drift).
  def wrong_totp_code(secret)
    valid = [ -60, -30, 0, 30, 60 ].map { |offset| totp_code(secret, at: Time.current + offset) }
    (0..999_999).lazy.map { |n| format("%06d", n) }.find { |code| valid.exclude?(code) }
  end

  # Turns 2FA on directly and returns the plain recovery codes.
  def enable_two_factor_for(user, secret = User.generate_otp_secret)
    user.enable_two_factor!(secret, totp_code(secret))
  end
end
