require "test_helper"

class Settings::TwoFactorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "routes live under /settings/two_factor" do
    assert_equal "/settings/two_factor", settings_two_factor_path
    assert_equal "/settings/two_factor/new", new_settings_two_factor_path
  end

  test "requires sign in for every action" do
    get settings_two_factor_path
    assert_redirected_to new_session_path

    get new_settings_two_factor_path
    assert_redirected_to new_session_path

    post settings_two_factor_path, params: { code: "123456" }
    assert_redirected_to new_session_path

    delete settings_two_factor_path, params: { code: "123456" }
    assert_redirected_to new_session_path
  end

  test "settings page links to two-factor and shows whether it is on" do
    sign_in_as @user
    get settings_sessions_path
    assert_select "a[href=?]", settings_two_factor_path, text: "Two-factor authentication"
    assert_select "#two-factor-heading ~ p", text: /Off/

    enable_two_factor_for(@user)
    get settings_sessions_path
    assert_select "#two-factor-heading ~ p", text: /On/
  end

  test "show offers setup when off" do
    sign_in_as @user
    get settings_two_factor_path

    assert_response :success
    assert_select "h1", "Two-factor authentication"
    assert_match "Off", response.body
    assert_select "a[href=?]", new_settings_two_factor_path
  end

  test "new shows an inline SVG QR code and the secret for manual entry" do
    sign_in_as @user
    get new_settings_two_factor_path

    assert_response :success
    assert_select "svg[role=img][aria-label] path[d]"
    secret = pending_secret
    assert_match(/\A[A-Z2-7]{32}\z/, secret)
    assert_select "label", "Authentication code"

    get new_settings_two_factor_path
    assert_equal secret, pending_secret, "reloading keeps the same secret so a scanned code still works"
    assert_not @user.reload.two_factor_enabled?, "nothing is saved until a code is verified"
  end

  test "a valid code enables two-factor and shows recovery codes once" do
    sign_in_as @user
    get new_settings_two_factor_path
    secret = pending_secret

    post settings_two_factor_path, params: { code: totp_code(secret) }

    assert_response :success
    assert_select "h1", "Save your recovery codes"
    assert_equal "no-store", response.headers["Cache-Control"]
    codes = css_select("ul[aria-label='Recovery codes'] li").map { |li| li.text.strip }
    assert_equal 10, codes.size

    @user.reload
    assert @user.two_factor_enabled?
    assert_equal secret, @user.otp_secret
    assert_equal 10, @user.recovery_codes.count
    digests = @user.recovery_codes.pluck(:code_digest)
    codes.each { |code| assert_not_includes digests, code }

    get settings_two_factor_path
    assert_match "On", response.body
    codes.each { |code| assert_no_match code, response.body }

    get new_settings_two_factor_path
    assert_redirected_to settings_two_factor_path
  end

  test "a code with a space and one step of drift is accepted" do
    sign_in_as @user
    get new_settings_two_factor_path
    code = totp_code(pending_secret, at: 30.seconds.ago)

    post settings_two_factor_path, params: { code: "#{code[0, 3]} #{code[3, 3]}" }
    assert_response :success
    assert @user.reload.two_factor_enabled?
  end

  test "a wrong code does not enable two-factor" do
    sign_in_as @user
    get new_settings_two_factor_path
    secret = pending_secret

    [ wrong_totp_code(secret), "", "abcdef", totp_code(secret, at: 5.minutes.ago) ].each do |code|
      post settings_two_factor_path, params: { code: code }
      assert_response :unprocessable_entity
      assert_match "That code didn&#39;t match", response.body
      assert_equal secret, pending_secret
    end

    @user.reload
    assert_not @user.two_factor_enabled?
    assert_nil @user.otp_secret
    assert_equal 0, @user.recovery_codes.count
  end

  test "create without visiting new first redirects to setup" do
    sign_in_as @user
    post settings_two_factor_path, params: { code: "123456" }
    assert_redirected_to new_settings_two_factor_path
    assert_not @user.reload.two_factor_enabled?
  end

  test "create cannot replace an existing secret" do
    secret = User.generate_otp_secret
    enable_two_factor_for(@user, secret)
    sign_in_as @user

    post settings_two_factor_path, params: { code: totp_code(secret) }
    assert_redirected_to settings_two_factor_path
    assert_equal secret, @user.reload.otp_secret
  end

  test "disabling with a valid code turns two-factor off" do
    secret = User.generate_otp_secret
    enable_two_factor_for(@user, secret)
    sign_in_as @user

    get settings_two_factor_path
    assert_select "label", "Authentication or recovery code"

    delete settings_two_factor_path, params: { code: totp_code(secret) }
    assert_redirected_to settings_two_factor_path
    follow_redirect!
    assert_match "Two-factor authentication is off.", response.body

    @user.reload
    assert_not @user.two_factor_enabled?
    assert_nil @user.otp_secret
    assert_equal 0, @user.recovery_codes.count
  end

  test "disabling with a wrong code keeps two-factor on" do
    secret = User.generate_otp_secret
    enable_two_factor_for(@user, secret)
    sign_in_as @user

    [ wrong_totp_code(secret), "", "aaaaa-aaaaa" ].each do |code|
      delete settings_two_factor_path, params: { code: code }
      assert_response :unprocessable_entity
      assert_match "That code didn&#39;t match", response.body
    end
    assert @user.reload.two_factor_enabled?
  end

  test "a recovery code can disable two-factor, but only once" do
    secret = User.generate_otp_secret
    codes = enable_two_factor_for(@user, secret)
    sign_in_as @user

    delete settings_two_factor_path, params: { code: codes.first }
    assert_redirected_to settings_two_factor_path
    assert_not @user.reload.two_factor_enabled?

    # Re-enable; the spent code (and every old one) no longer works.
    enable_two_factor_for(@user, secret)
    delete settings_two_factor_path, params: { code: codes.first }
    assert_response :unprocessable_entity
    assert @user.reload.two_factor_enabled?
  end

  test "a spent recovery code is rejected" do
    codes = enable_two_factor_for(@user)
    @user.verify_two_factor(codes.first)
    sign_in_as @user

    delete settings_two_factor_path, params: { code: codes.first }
    assert_response :unprocessable_entity
    assert @user.reload.two_factor_enabled?
  end

  test "setup and disabling require sudo" do
    secret = User.generate_otp_secret
    sign_in_as @user
    travel 16.minutes

    get settings_two_factor_path
    assert_response :success, "viewing the status doesn't need sudo"

    get new_settings_two_factor_path
    assert_redirected_to new_sudo_path(return_to: new_settings_two_factor_path)

    post settings_two_factor_path, params: { code: "123456" }
    assert_redirected_to new_sudo_path(return_to: settings_two_factor_path)

    enable_two_factor_for(@user, secret)
    delete settings_two_factor_path, params: { code: totp_code(secret) }
    assert_redirected_to new_sudo_path(return_to: settings_two_factor_path)
    assert @user.reload.two_factor_enabled?

    post sudo_path, params: { password: valid_password, return_to: settings_two_factor_path }
    delete settings_two_factor_path, params: { code: totp_code(secret) }
    assert_redirected_to settings_two_factor_path
    assert_not @user.reload.two_factor_enabled?
  end

  test "rate limits attempts to disable" do
    secret = User.generate_otp_secret
    enable_two_factor_for(@user, secret)
    sign_in_as @user

    10.times { delete settings_two_factor_path, params: { code: wrong_totp_code(secret) } }
    delete settings_two_factor_path, params: { code: totp_code(secret) }
    assert_redirected_to settings_two_factor_path
    follow_redirect!
    assert_match "Try again later.", response.body
    assert @user.reload.two_factor_enabled?
  end

  private
    def pending_secret
      css_select("#otp-secret").first.text.gsub(/\s/, "")
    end
end
