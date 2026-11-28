require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "associations" do
    account = accounts(:acme)
    assert_equal users(:one), account.owner
    assert_includes account.users, users(:one)
    assert_includes account.account_users, account_users(:acme_owner)
    assert_not_includes account.users, users(:two)
  end

  test "name is required" do
    account = Account.new(owner: users(:one))
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "personal defaults to false" do
    assert_not Account.new.personal?
  end

  test "owner? is true only for the owner" do
    assert accounts(:acme).owner?(users(:one))
    assert_not accounts(:acme).owner?(users(:two))
    assert_not accounts(:acme).owner?(nil)
  end

  test "a user can have only one personal account" do
    duplicate = Account.new(name: "Another", personal: true, owner: users(:one))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:owner_id], "has already been taken"

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save!(validate: false)
    end
  end

  test "a user can own many shared accounts" do
    assert Account.create(name: "Initech", owner: users(:one)).persisted?
    assert_equal 2, users(:one).owned_accounts.where(personal: false).count
  end

  test "team accounts are limited per owner" do
    owner = users(:one)
    (Account::TEAM_ACCOUNT_LIMIT - 1).times { |i| Account.create!(name: "Team #{i}", owner: owner) }

    extra = Account.new(name: "Extra", owner: owner)
    assert_not extra.valid?
    assert_includes extra.errors[:base].first, "at most 10 team accounts"

    assert Account.new(name: "Theirs", owner: users(:two)).valid?
    assert accounts(:acme).valid?, "existing accounts stay valid at the limit"
  end

  test "personal accounts can't be deleted" do
    account = accounts(:one_personal)
    assert_not account.destroy
    assert Account.exists?(account.id)
    assert_includes account.errors[:base], "Personal accounts can't be deleted"
  end

  test "shared accounts can be deleted along with their memberships" do
    account = accounts(:acme)
    assert_difference -> { AccountUser.count }, -1 do
      assert account.destroy
    end
    assert_not Account.exists?(account.id)
    assert User.exists?(users(:one).id)
  end
end
