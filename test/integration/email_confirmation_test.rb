require "test_helper"

class EmailConfirmationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(email_confirmed_at: nil)
  end

  test "valid token confirms email" do
    token = @user.generate_token_for(:email_confirmation)
    get email_confirmation_url(token: token)
    assert_redirected_to root_path
    assert_equal "Your email has been confirmed.", flash[:notice]
    assert @user.reload.email_confirmed?
  end

  test "invalid token does not confirm email" do
    get email_confirmation_url(token: "invalid")
    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link.", flash[:alert]
    assert_not @user.reload.email_confirmed?
  end
end
