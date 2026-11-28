require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(email_address: "test@example.com", password: valid_password)
    assert user.valid?
  end

  test "invalid email address" do
    user = User.new(email_address: "invalid", password: valid_password)
    assert_not user.valid?
  end

  test "password length minimum 12" do
    user = User.new(email_address: "test@example.com", password: short_password)
    assert_not user.valid?
  end

  test "normalizes email address" do
    user = User.create!(email_address: "  TEST@EXAMPLE.COM  ", password: valid_password)
    assert_equal "test@example.com", user.email_address
  end

  test "active scope excludes soft-deleted users" do
    one = users(:one)
    two = users(:two)
    one.update_columns(deleted_at: Time.current)

    assert_not_includes User.active, one
    assert_includes User.active, two
  end

  test "soft_delete! sets deleted_at, destroys sessions and frees the email" do
    user = users(:one)
    user.sessions.create!(user_agent: "a", ip_address: "192.0.2.1")
    user.sessions.create!(user_agent: "b", ip_address: "192.0.2.2")
    other_session = users(:two).sessions.create!(user_agent: "c", ip_address: "192.0.2.3")

    freeze_time do
      user.soft_delete!
      assert_equal Time.current, user.reload.deleted_at
    end

    assert user.deleted?
    assert_equal "deleted-#{user.id}@invalid", user.email_address
    assert_equal 0, user.sessions.count
    assert Session.exists?(other_session.id)
    assert User.exists?(user.id)
  end

  test "the freed email can be registered again" do
    users(:one).soft_delete!
    assert User.new(email_address: "one@example.com", password: valid_password).valid?
  end

  test "deleted? is false for active users" do
    assert_not users(:one).deleted?
  end
end
