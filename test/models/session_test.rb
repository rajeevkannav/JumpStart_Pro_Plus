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
end
