require "test_helper"

class SignUpPersonalAccountTest < ActionDispatch::IntegrationTest
  test "a new user has exactly one personal account they own" do
    assert_difference -> { Account.count } => 1, -> { AccountUser.count } => 1 do
      post registration_path, params: { user: { email_address: "fresh@example.com", password: valid_password, password_confirmation: valid_password } }
    end
    assert_redirected_to root_path

    user = User.find_by!(email_address: "fresh@example.com")
    assert_equal 1, user.accounts.count
    account = user.accounts.first
    assert account.personal?
    assert account.owner?(user)
    assert_equal "fresh@example.com", account.name
    assert_equal "owner", account.role_for(user)

    get accounts_path
    assert_response :success
    assert_select "main li", text: /fresh@example\.com/, count: 1
    assert_match "Personal", response.body
  end

  test "a failed sign-up creates no account" do
    assert_no_difference -> { Account.count } do
      post registration_path, params: { user: { email_address: "fresh@example.com", password: short_password, password_confirmation: short_password } }
    end
    assert_response :unprocessable_entity
  end
end
