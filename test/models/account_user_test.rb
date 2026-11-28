require "test_helper"

class AccountUserTest < ActiveSupport::TestCase
  test "role defaults to member" do
    assert_equal "member", AccountUser.new.role
  end

  test "role must be owner or member" do
    membership = AccountUser.new(account: accounts(:acme), user: users(:two), role: "admin")
    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "a user can join a shared account as a member" do
    membership = accounts(:acme).account_users.create!(user: users(:two))
    assert_equal "member", membership.role
    assert_not membership.owner?
    assert_includes users(:two).accounts, accounts(:acme)
  end

  test "a membership is unique per account and user" do
    duplicate = AccountUser.new(account: accounts(:acme), user: users(:one), role: "member")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save!(validate: false)
    end
  end

  test "personal accounts can't have other members" do
    membership = AccountUser.new(account: accounts(:one_personal), user: users(:two))
    assert_not membership.valid?
    assert_includes membership.errors[:base], "Personal accounts can't have other members"
  end
end
