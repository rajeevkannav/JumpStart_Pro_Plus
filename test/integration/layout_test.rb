require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  test "app shell when signed out" do
    get root_url
    assert_response :success
  end

  test "app shell when signed in" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: valid_password }
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end
end
