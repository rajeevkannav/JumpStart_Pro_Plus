require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get new_password_path
    assert_response :success
  end

  test "should update password" do
    token = @user.generate_token_for(:password_reset)
    patch password_path(token), params: { user: { password: "new_password1234", password_confirmation: "new_password1234" } }
    assert_redirected_to new_session_path
  end
end
