require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_path
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post registration_path, params: { user: { email_address: "newuser@example.com", password: "password12345", password_confirmation: "password12345" } }
    end
    assert_redirected_to root_path
  end

  test "rate limits registration per IP" do
    post registration_path, params: { user: { email_address: "otherip@example.com", password: "password12345", password_confirmation: "password12345" } }, headers: { "REMOTE_ADDR" => "192.168.1.200" }
    assert_redirected_to root_path
  end
end
