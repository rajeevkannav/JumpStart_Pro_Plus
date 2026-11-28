require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should create session" do
    post session_url, params: { email_address: @user.email_address, password: "password123456" }
    assert_redirected_to root_url
  end

  test "should destroy session" do
    sign_in_as(@user)
    delete session_url
    assert_redirected_to new_session_url
  end
end
