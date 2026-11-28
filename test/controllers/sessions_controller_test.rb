require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "user@example.com",
      password: "password12345",
      password_confirmation: "password12345"
    )
  end

  test "should get new" do
    get new_session_path
    assert_response :success
  end

  test "should create session with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password12345" }
    assert_redirected_to root_path
  end

  test "rate limits session creation per IP" do
    ip = "192.168.1.1"
    10.times do
      post session_path(format: :json), params: { email_address: @user.email_address, password: "wrongpassword" }, headers: { "REMOTE_ADDR" => ip }
    end
    post session_path(format: :json), params: { email_address: @user.email_address, password: "wrongpassword" }, headers: { "REMOTE_ADDR" => ip }
    assert_response :too_many_requests
  end
end
