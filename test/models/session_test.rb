require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "a new session starts in sudo mode" do
    session = @user.sessions.create!
    assert_not_nil session.sudo_at
    assert session.sudo?
  end

  test "sudo expires after 15 minutes" do
    session = @user.sessions.create!
    travel 14.minutes
    assert session.sudo?
    travel 2.minutes
    assert_not session.sudo?
  end

  test "a session without sudo_at is not in sudo mode" do
    session = @user.sessions.create!
    session.update!(sudo_at: nil)
    assert_not session.sudo?
  end

  test "sudo! restores sudo mode" do
    session = @user.sessions.create!
    travel 20.minutes
    assert_not session.sudo?
    session.sudo!
    assert session.reload.sudo?
    assert_in_delta Time.current, session.sudo_at, 1.second
  end

  test "current_account defaults to the personal account" do
    session = @user.sessions.create!
    assert_equal accounts(:one_personal), session.current_account
  end

  test "current_account is the selected account the user belongs to" do
    session = @user.sessions.create!(account: accounts(:acme))
    assert_equal accounts(:acme), session.current_account
  end

  test "an account the user doesn't belong to can't be selected" do
    session = @user.sessions.create!
    assert_not session.update(account: accounts(:globex))
    assert_includes session.errors[:account], "must be an account you belong to"
  end

  test "a foreign account id falls back to the personal account" do
    session = @user.sessions.create!
    session.update_column(:account_id, accounts(:globex).id)
    assert_equal accounts(:one_personal), session.reload.current_account
  end
end
