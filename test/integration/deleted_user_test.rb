require "test_helper"

class DeletedUserTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = users(:one)
  end

  test "a deleted user cannot sign in even with the right password" do
    # Deleted before the email is freed, e.g. a purge that kept the address.
    @user.update_columns(deleted_at: Time.current)

    post session_url, params: { email_address: "one@example.com", password: "password123456" }
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
    assert_equal 0, @user.sessions.count
  end

  test "a deleted user gets the same response as a wrong password" do
    post session_url, params: { email_address: "two@example.com", password: "wrong-password-123" }
    wrong_password_alert = flash[:alert]

    @user.update_columns(deleted_at: Time.current)
    post session_url, params: { email_address: "one@example.com", password: "password123456" }
    assert_equal wrong_password_alert, flash[:alert]
  end

  test "a deleted user cannot request a password reset" do
    @user.update_columns(deleted_at: Time.current)

    assert_no_enqueued_emails do
      post passwords_path, params: { email_address: "one@example.com" }
    end
    assert_redirected_to new_session_path
    assert_equal "Password reset instructions sent (if user with that email address exists).", flash[:notice]
  end

  test "an active user can still request a password reset" do
    assert_enqueued_emails 1 do
      post passwords_path, params: { email_address: "one@example.com" }
    end
  end

  test "a reset token issued before deletion no longer works" do
    token = @user.password_reset_token
    @user.soft_delete!

    get edit_password_path(token)
    assert_redirected_to new_password_path

    put password_path(token), params: { password: "brandnewpass123", password_confirmation: "brandnewpass123" }
    assert_redirected_to new_password_path
    assert_nil User.active.find_by(id: @user.id)
    assert_not @user.reload.authenticate("brandnewpass123")
  end
end
