require "test_helper"

class AccountUserTest < ActiveSupport::TestCase
  test "role defaults to member" do
    assert_equal "member", AccountUser.new.role
  end

  test "role must be owner, admin or member" do
    membership = AccountUser.new(account: accounts(:acme), user: users(:two), role: "superuser")
    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"

    membership.role = "admin"
    assert membership.valid?
    assert membership.admin?
  end

  test "roles imply lower roles" do
    assert_equal %i[ owner admin member ], AccountUser.new(role: "owner").roles
    assert_equal %i[ admin member ], AccountUser.new(role: "admin").roles
    assert_equal %i[ member ], AccountUser.new(role: "member").roles
  end

  test "change_role! switches between member and admin only" do
    acme = accounts(:acme)
    membership = acme.account_users.create!(user: users(:two))

    acme.change_role!(membership, "admin")
    assert_equal "admin", membership.reload.role
    acme.change_role!(membership, "member")
    assert_equal "member", membership.reload.role

    error = assert_raises(Account::MembershipError) { acme.change_role!(membership, "owner") }
    assert_equal "Choose member or admin.", error.message
    assert_equal "member", membership.reload.role
    assert_equal users(:one), acme.reload.owner

    error = assert_raises(Account::MembershipError) { acme.change_role!(account_users(:acme_owner), "admin") }
    assert_match "Transfer ownership instead", error.message
    assert_equal "owner", account_users(:acme_owner).reload.role

    assert_raises(ArgumentError) { accounts(:globex).change_role!(membership, "admin") }
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
