require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(email_address: "test@example.com", password: "Secret123456!")
    assert user.valid?
  end

  test "invalid email address" do
    user = User.new(email_address: "invalid", password: "Secret123456!")
    assert_not user.valid?
  end

  test "password length minimum 12" do
    user = User.new(email_address: "test@example.com", password: "short")
    assert_not user.valid?
  end

  test "normalizes email address" do
    user = User.create!(email_address: "  TEST@EXAMPLE.COM  ", password: "Secret123456!")
    assert_equal "test@example.com", user.email_address
  end
end
