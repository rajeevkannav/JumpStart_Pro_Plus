require "test_helper"

class AccountMembershipTest < ActiveSupport::TestCase
  setup do
    @acme = accounts(:acme)
    @owner = users(:one)
    @member = users(:two)
    @membership = @acme.account_users.create!(user: @member, role: "member")
  end

  test "remove_member! destroys the membership and resets sessions in that account" do
    session = @member.sessions.create!(account: @acme)
    other_session = @member.sessions.create!(account: accounts(:globex))

    @acme.remove_member!(@membership)

    assert_not @acme.users.include?(@member)
    assert_nil session.reload.account_id
    assert_equal accounts(:globex), other_session.reload.account
    assert_equal @member.personal_account, session.current_account
  end

  test "remove_member! refuses the owner" do
    assert_raises(Account::MembershipError) do
      @acme.remove_member!(account_users(:acme_owner))
    end
    assert @acme.users.include?(@owner)
  end

  test "remove_member! refuses another account's membership" do
    assert_raises(ArgumentError) do
      @acme.remove_member!(account_users(:globex_owner))
    end
  end

  test "transfer_ownership_to! swaps owner_id and roles" do
    @acme.transfer_ownership_to!(@member)

    @acme.reload
    assert_equal @member, @acme.owner
    assert_equal "owner", @acme.role_for(@member)
    assert_equal "member", @acme.role_for(@owner)
  end

  test "transfer_ownership_to! only to an existing member" do
    outsider = User.create!(email_address: "outsider@example.com", password: valid_password)

    assert_raises(Account::MembershipError) { @acme.transfer_ownership_to!(outsider) }
    assert_equal @owner, @acme.reload.owner
    assert_equal "owner", @acme.role_for(@owner)
  end

  test "transfer_ownership_to! refuses personal accounts and the current owner" do
    assert_raises(Account::MembershipError) { accounts(:one_personal).transfer_ownership_to!(@member) }
    assert_raises(Account::MembershipError) { @acme.transfer_ownership_to!(@owner) }
    assert_equal @owner, @acme.reload.owner
  end

  test "transfer_ownership_to! is atomic" do
    # Fail the last step (owner_id) after both roles were already written.
    @acme.define_singleton_method(:update!) { |*| raise ActiveRecord::RecordInvalid, Account.new }

    begin
      assert_raises(ActiveRecord::RecordInvalid) { @acme.transfer_ownership_to!(@member) }
    ensure
      @acme.singleton_class.send(:remove_method, :update!)
    end

    @acme.reload
    assert_equal @owner, @acme.owner
    assert_equal "owner", @acme.role_for(@owner)
    assert_equal "member", @acme.role_for(@member)
  end

  test "transfer_ownership_to! respects the new owner's team account limit" do
    (Account::TEAM_ACCOUNT_LIMIT - 1).times do |i|
      Account.create!(name: "Team #{i}", owner: @member, personal: false)
    end

    assert_raises(Account::MembershipError) { @acme.transfer_ownership_to!(@member) }
    assert_equal @owner, @acme.reload.owner
  end
end
