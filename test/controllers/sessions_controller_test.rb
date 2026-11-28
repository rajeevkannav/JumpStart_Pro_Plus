require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "user@example.com",
      password: valid_password,
      password_confirmation: valid_password
    )
  end

  test "should get new" do
    get new_session_path
    assert_response :success
  end

  test "should create session with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: valid_password }
    assert_redirected_to root_path
  end

  test "rate limits session creation per IP" do
    ip = "192.168.1.1"
    10.times do
      post session_path(format: :json), params: { email_address: @user.email_address, password: wrong_password }, headers: { "REMOTE_ADDR" => ip }
    end
    post session_path(format: :json), params: { email_address: @user.email_address, password: wrong_password }, headers: { "REMOTE_ADDR" => ip }
    assert_response :too_many_requests
  end
end
