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

  test "creating a user creates exactly one personal account they own" do
    user = nil
    assert_difference -> { Account.count } => 1, -> { AccountUser.count } => 1 do
      user = User.create!(email_address: "new@example.com", password: valid_password)
    end

    assert_equal 1, user.accounts.count
    account = user.personal_account
    assert account.personal?
    assert_equal "new@example.com", account.name
    assert account.owner?(user)
    assert_equal "owner", account.role_for(user)
  end

  test "an invalid user creates no account" do
    assert_no_difference -> { Account.count } do
      User.create(email_address: "invalid", password: valid_password)
    end
  end

  test "the personal account is rolled back with the user" do
    assert_no_difference [ -> { User.count }, -> { Account.count }, -> { AccountUser.count } ] do
      User.transaction do
        User.create!(email_address: "rollback@example.com", password: valid_password)
        raise ActiveRecord::Rollback
      end
    end
  end

  test "account associations" do
    user = users(:one)
    assert_equal accounts(:one_personal), user.personal_account
    assert_equal [ accounts(:acme), accounts(:one_personal) ].sort_by(&:id), user.accounts.order(:id).to_a
    assert_not_includes user.accounts, accounts(:two_personal)
  end

  test "soft_delete! renames the personal account" do
    user = users(:one)
    user.soft_delete!
    assert_equal "deleted-#{user.id}@invalid", user.personal_account.reload.name
  end

  test "deleted? is false for active users" do
    assert_not users(:one).deleted?
  end
end
