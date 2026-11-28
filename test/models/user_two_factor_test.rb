require "test_helper"

class UserTwoFactorTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @secret = User.generate_otp_secret
  end

  test "two-factor is off by default" do
    assert_not @user.two_factor_enabled?
    assert_not @user.verify_two_factor(totp_code(@secret))
  end

  test "enable_two_factor! with a valid code turns it on and returns recovery codes" do
    codes = @user.enable_two_factor!(@secret, totp_code(@secret))

    assert_equal 10, codes.size
    @user.reload
    assert @user.two_factor_enabled?
    assert_equal @secret, @user.otp_secret
    assert_equal 10, @user.recovery_codes.count
  end

  test "enable_two_factor! with a wrong or malformed code changes nothing" do
    [ wrong_totp_code(@secret), "", "abcdef", "12345", "1234567", nil ].each do |code|
      assert_nil @user.enable_two_factor!(@secret, code)
    end

    @user.reload
    assert_not @user.two_factor_enabled?
    assert_nil @user.otp_secret
    assert_equal 0, @user.recovery_codes.count
  end

  test "codes from the previous and next step are accepted, older ones are not" do
    assert User.otp_code_valid?(@secret, totp_code(@secret, at: 30.seconds.ago))
    assert User.otp_code_valid?(@secret, totp_code(@secret, at: 30.seconds.from_now))
    assert_not User.otp_code_valid?(@secret, totp_code(@secret, at: 2.minutes.ago))
    assert_not User.otp_code_valid?(@secret, totp_code(@secret, at: 2.minutes.from_now))
  end

  test "otp_secret is encrypted at rest" do
    enable_two_factor_for(@user, @secret)

    raw = User.connection.select_value(User.where(id: @user.id).select(:otp_secret).to_sql)
    assert raw.present?
    assert_not_includes raw, @secret
    assert_equal @secret, @user.reload.otp_secret
  end

  test "verify_two_factor accepts a current code repeatedly" do
    enable_two_factor_for(@user, @secret)

    assert @user.verify_two_factor(totp_code(@secret))
    assert @user.verify_two_factor(totp_code(@secret))
    assert_not @user.verify_two_factor(wrong_totp_code(@secret))
  end

  test "each recovery code works only once" do
    codes = enable_two_factor_for(@user, @secret)

    assert @user.verify_two_factor(codes.first)
    assert_not @user.verify_two_factor(codes.first)
    assert @user.verify_two_factor(codes.second.upcase)
    assert_equal 8, @user.recovery_codes.unused.count
  end

  test "another user's recovery codes don't work" do
    other = users(:two)
    other_codes = enable_two_factor_for(other)
    enable_two_factor_for(@user, @secret)

    assert_not @user.verify_two_factor(other_codes.first)
    assert_equal 10, other.recovery_codes.unused.count
  end

  test "disable_two_factor! clears the secret and recovery codes" do
    enable_two_factor_for(@user, @secret)
    @user.disable_two_factor!

    @user.reload
    assert_not @user.two_factor_enabled?
    assert_nil @user.otp_secret
    assert_nil @user.otp_enabled_at
    assert_equal 0, @user.recovery_codes.count
  end
end
