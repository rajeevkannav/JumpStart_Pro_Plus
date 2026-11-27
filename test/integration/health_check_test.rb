require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "returns 200 on /up" do
    get "/up"
    assert_response :success
  end
end
