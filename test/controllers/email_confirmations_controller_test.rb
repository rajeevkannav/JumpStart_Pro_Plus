require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
  end

  test "should confirm email with valid token" do
    token = @user.generate_token_for(:email_confirmation)
    get email_confirmation_url(token: token)
    assert_redirected_to root_url
    assert @user.reload.email_confirmed?
  end

  test "should fail email confirmation with invalid token" do
    get email_confirmation_url(token: "invalid")
    assert_redirected_to root_url
  end
end
