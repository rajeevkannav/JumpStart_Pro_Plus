require "test_helper"

class AuthFlowTest < ActionDispatch::IntegrationTest
  test "sign up creates user and signs in" do
    post registration_path, params: { user: { email_address: "test@example.com", password: valid_password } }
    assert_redirected_to root_path
    assert_equal 1, Session.count
  end

  test "short password returns 422" do
    post registration_path, params: { user: { email_address: "test@example.com", password: short_password } }
    assert_response :unprocessable_entity
  end
end
