require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "/up returns 200" do
    get "/up"
    assert_response :success
  end

  test "root returns 200" do
    get "/"
    assert_response :success
    assert_select "h1", "Jumpstart Pro Plus"
  end
end
