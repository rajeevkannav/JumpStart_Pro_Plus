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

  test "root reports the database as connected" do
    get "/"
    assert_response :success
    assert_includes response.body, "Connected"
    assert_not_includes response.body, "Disconnected"
  end

  test "root reports the database as disconnected when it is unreachable" do
    connection = ActiveRecord::Base.connection
    connection.define_singleton_method(:select_value) { |*| raise ActiveRecord::ConnectionNotEstablished }
    begin
      get "/"
    ensure
      connection.singleton_class.remove_method(:select_value)
    end
    assert_response :success
    assert_includes response.body, "Disconnected"
  end
end
