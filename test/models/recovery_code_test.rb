require "test_helper"

class RecoveryCodeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "regenerate_for creates ten hashed codes and returns the plain ones" do
    codes = RecoveryCode.regenerate_for(@user)

    assert_equal 10, codes.size
    assert_equal 10, codes.uniq.size
    codes.each { |code| assert_match(/\A[a-z0-9]{5}-[a-z0-9]{5}\z/, code) }
    assert_equal 10, @user.recovery_codes.count

    digests = @user.recovery_codes.pluck(:code_digest)
    codes.each do |code|
      assert_not_includes digests, code
      assert_not_includes digests, RecoveryCode.normalize(code)
    end
    assert digests.all? { |digest| BCrypt::Password.valid_hash?(digest) }
  end

  test "regenerate_for replaces the previous codes" do
    old_codes = RecoveryCode.regenerate_for(@user)
    RecoveryCode.regenerate_for(@user)

    assert_equal 10, @user.recovery_codes.count
    assert_not @user.recovery_codes.any? { |recovery_code| recovery_code.matches?(old_codes.first) }
  end

  test "matches ignores case, dashes and spaces" do
    code = RecoveryCode.regenerate_for(@user).first
    recovery_code = @user.recovery_codes.detect { |rc| rc.matches?(code) }

    assert recovery_code
    assert recovery_code.matches?(" #{code.upcase.delete('-')} ")
    assert_not recovery_code.matches?("aaaaa-aaaaa")
  end

  test "consume! only succeeds once" do
    RecoveryCode.regenerate_for(@user)
    recovery_code = @user.recovery_codes.first

    assert recovery_code.consume!
    assert recovery_code.reload.used_at
    assert_not recovery_code.consume!
  end
end
