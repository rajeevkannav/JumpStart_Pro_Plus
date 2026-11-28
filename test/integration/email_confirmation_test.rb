require "test_helper"

class EmailConfirmationTest < ActionDispatch::IntegrationTest
  test "invalid token does not confirm email" do
    get email_confirmation_url(token: "invalid")
    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link.", flash[:alert]
  end
end
