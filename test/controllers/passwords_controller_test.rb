require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get new_password_url
    assert_response :success
  end

  test "should update password" do
    patch password_url(token: "dummy"), params: { password: "newpassword123", password_confirmation: "newpassword123" }
    assert_response :redirect
  end
end
