require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "show confirms email with valid token" do
    user = User.create!(email_address: "confirm_me@example.com", password: valid_password)
    token = user.generate_token_for(:email_confirmation)

    get email_confirmation_url(token: token)
    assert_redirected_to root_path
    assert_equal "Your email has been confirmed.", flash[:notice]
    assert user.reload.email_confirmed?
  end

  test "show with invalid token shows alert" do
    get email_confirmation_url(token: "invalid-token")
    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link.", flash[:alert]
  end

  test "create resends confirmation email for logged in user" do
    user = User.create!(email_address: "resend@example.com", password: valid_password)
    post session_url, params: { email_address: user.email_address, password: valid_password }

    post email_confirmation_url
    assert_redirected_to root_path
    assert_equal "Confirmation email sent.", flash[:notice]
  end

  test "rate limits confirmation resends per user" do
    user = User.create!(email_address: "ratelimit@example.com", password: valid_password)
    post session_url, params: { email_address: user.email_address, password: valid_password }

    3.times do
      post email_confirmation_url
      assert_redirected_to root_path
    end

    post email_confirmation_url
    assert_redirected_to root_path
    assert_equal "Try again later.", flash[:alert]
  end
end
