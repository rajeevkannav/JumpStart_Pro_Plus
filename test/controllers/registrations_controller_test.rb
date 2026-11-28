require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post registration_url, params: {
        user: {
          email_address: "newuser@example.com",
          password: "Secret123456!",
          password_confirmation: "Secret123456!"
        }
      }
    end

    assert_redirected_to root_url
  end

  test "should not create user with invalid params" do
    assert_no_difference("User.count") do
      post registration_url, params: {
        user: {
          email_address: "invalid",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
