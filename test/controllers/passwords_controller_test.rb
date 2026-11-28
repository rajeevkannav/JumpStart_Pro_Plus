require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "user@example.com",
      password: valid_password,
      password_confirmation: valid_password
    )
  end

  test "should get new" do
    get new_password_path
    assert_response :success
  end

  test "should send password reset instructions" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_redirected_to new_session_path
    assert_equal "Password reset instructions sent (if user with that email address exists).", flash[:notice]
  end

  test "rate limits password resets per IP" do
    post passwords_path, params: { email_address: @user.email_address }, headers: { "REMOTE_ADDR" => "10.0.0.2" }
    assert_redirected_to new_session_path
  end
end
