require "test_helper"

# Two-factor settings belong to the signed-in user, not to an account:
# every role (owner, admin, member) in every account manages only their own
# second factor, the current account never changes what is reachable, and
# no request can reach another user's secret or recovery codes.
class TwoFactorAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)        # owns Acme
    @foreign_user = users(:two) # owns Globex (another tenant)
    @foreign_secret = User.generate_otp_secret
    @foreign_codes = enable_two_factor_for(@foreign_user, @foreign_secret)
  end

  test "owners, admins and members of a team can all manage their own two-factor" do
    admin = create_member(accounts(:acme), "admin")
    member = create_member(accounts(:acme), "member")

    [ @owner, admin, member ].each do |user|
      reset!
      sign_in_as user
      post account_switch_path(accounts(:acme))

      get settings_two_factor_path
      assert_response :success

      get new_settings_two_factor_path
      assert_response :success
      post settings_two_factor_path, params: { code: totp_code(pending_secret) }
      assert_response :success
      assert user.reload.two_factor_enabled?, "#{user.email_address} enabled 2FA"

      delete settings_two_factor_path, params: { code: totp_code(user.otp_secret) }
      assert_redirected_to settings_two_factor_path
      assert_not user.reload.two_factor_enabled?
    end
  end

  test "another tenant's secret is never shown and its codes can't be used" do
    sign_in_as @owner
    post account_switch_path(accounts(:acme))

    get settings_two_factor_path
    assert_match "Off", response.body

    get new_settings_two_factor_path
    assert_not_equal @foreign_secret, pending_secret
    assert_no_match @foreign_secret, response.body

    post settings_two_factor_path, params: { code: totp_code(@foreign_secret), user_id: @foreign_user.id }
    assert_not @owner.reload.two_factor_enabled?
    assert @foreign_user.reload.two_factor_enabled?
  end

  test "disabling can't target another tenant's user" do
    enable_two_factor_for(@owner)
    sign_in_as @owner

    delete settings_two_factor_path, params: { code: @foreign_codes.first, user_id: @foreign_user.id }
    assert_response :unprocessable_entity

    delete settings_two_factor_path, params: { code: totp_code(@foreign_secret), id: @foreign_user.id }
    assert_response :unprocessable_entity

    assert @owner.reload.two_factor_enabled?
    @foreign_user.reload
    assert @foreign_user.two_factor_enabled?
    assert_equal 10, @foreign_user.recovery_codes.unused.count
  end

  test "routes take no ids, so there is nothing to enumerate" do
    sign_in_as @owner
    get "/settings/two_factor/#{@foreign_user.id}"
    assert_response :not_found
  end

  private
    def create_member(account, role)
      user = User.create!(email_address: "#{role}-#{SecureRandom.hex(4)}@example.com", password: valid_password)
      account.account_users.create!(user: user, role: role)
      user
    end

    def pending_secret
      css_select("#otp-secret").first.text.gsub(/\s/, "")
    end
end
