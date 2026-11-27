require "test_helper"

class UpControllerTest < ActionDispatch::IntegrationTest
  test "should get up" do
    get "/up"
    assert_response :success
  end
end