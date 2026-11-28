require "test_helper"

class AccountInvitationTest < ActiveSupport::TestCase
  setup do
    @acme = accounts(:acme)
    @owner = users(:one)
  end

  def invite(email, account: @acme)
    account.invitations.create(email_address: email, invited_by: @owner)
  end

  test "normalises the email, generates a token and expires in 7 days" do
    invitation = invite("  New.Person@Example.COM ")

    assert invitation.persisted?
    assert_equal "new.person@example.com", invitation.email_address
    assert invitation.token.present?
    assert_in_delta 7.days.from_now, invitation.expires_at, 5.seconds
    assert invitation.acceptable?
  end

  test "requires a valid email address" do
    assert_not invite("not-an-email").persisted?
    assert_not invite("").persisted?
  end

  test "only one pending invitation per account and email" do
    assert invite("new@example.com").persisted?

    duplicate = invite("NEW@example.com")
    assert_not duplicate.persisted?
    assert_includes duplicate.errors[:email_address], "has already been invited"

    assert invite("new@example.com", account: accounts(:globex)).persisted?, "other accounts can invite the same email"
  end

  test "an expired invitation doesn't block a new one" do
    old = invite("new@example.com")
    old.update_columns(expires_at: 1.minute.ago)

    fresh = invite("new@example.com")
    assert fresh.persisted?
    assert_not AccountInvitation.exists?(old.id)
  end

  test "personal accounts can't invite" do
    invitation = invite("new@example.com", account: accounts(:one_personal))
    assert_not invitation.persisted?
    assert_includes invitation.errors[:base], "Personal accounts can't invite members"
  end

  test "existing members can't be invited" do
    invitation = invite("one@example.com")
    assert_not invitation.persisted?
    assert invitation.errors[:email_address].any?
  end

  test "accept! adds a member once and marks the invitation used" do
    invitation = invite("two@example.com")
    user = users(:two)

    assert_difference -> { @acme.account_users.count }, 1 do
      assert invitation.accept!(user)
    end
    assert_equal "member", @acme.role_for(user)
    assert invitation.reload.accepted?
    assert_not invitation.acceptable?

    assert_no_difference -> { AccountUser.count } do
      assert_not invitation.accept!(user)
    end
  end

  test "an expired invitation can't be accepted" do
    invitation = invite("two@example.com")
    invitation.update_columns(expires_at: 1.second.ago)

    assert invitation.expired?
    assert_no_difference -> { AccountUser.count } do
      assert_not invitation.accept!(users(:two))
    end
  end

  test "deleting the account deletes its invitations" do
    invite("new@example.com")
    assert_difference -> { AccountInvitation.count }, -1 do
      @acme.destroy
    end
  end
end
