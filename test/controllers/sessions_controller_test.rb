require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  setup do
    @user = User.create!(email_address: "test@example.com", password: "password123456")
  end

  test "should create with invalid credentials" do
    post session_url, params: { email_address: "wrong@example.com", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "should destroy" do
    sign_in_as(@user)
    delete session_url
    assert_redirected_to new_session_path
  end
end
