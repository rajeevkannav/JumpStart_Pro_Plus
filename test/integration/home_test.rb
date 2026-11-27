require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "should get root" do
    get "/"
    assert_response :success
    assert_select "h1", "JumpStart Pro Plus"
  end
end