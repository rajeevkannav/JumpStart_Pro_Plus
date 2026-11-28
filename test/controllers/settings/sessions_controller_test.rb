require "test_helper"

class Settings::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @phone = @user.sessions.create!(user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1", ip_address: "203.0.113.7")
    @laptop = @user.sessions.create!(user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/120.0", ip_address: "198.51.100.4")
    @foreign = @other_user.sessions.create!(user_agent: "Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0 Safari/537.36", ip_address: "192.0.2.99")
  end

  test "requires sign in" do
    get settings_sessions_path
    assert_redirected_to new_session_path

    assert_no_difference -> { Session.count } do
      delete others_settings_sessions_path
    end
    assert_redirected_to new_session_path
  end

  test "index lists only the current user's sessions and marks this device" do
    sign_in_as @user
    get settings_sessions_path

    assert_response :success
    assert_select "h1", "Active sessions"
    assert_match "Safari on iOS", response.body
    assert_match "203.0.113.7", response.body
    assert_match "Firefox on Windows", response.body
    assert_match "198.51.100.4", response.body
    assert_match "This device", response.body
    assert_no_match "192.0.2.99", response.body
    assert_no_match "Chrome on Linux", response.body
    assert_select "li", text: /This device/, count: 1
  end

  test "navbar links to sessions when signed in" do
    sign_in_as @user
    follow_redirect!
    assert_select "nav a[href=?]", settings_sessions_path, text: "Sessions"
  end

  test "destroy signs out one of the user's other sessions" do
    sign_in_as @user
    assert_difference -> { @user.sessions.count }, -1 do
      delete settings_session_path(@phone)
    end
    assert_redirected_to settings_sessions_path
    assert_not Session.exists?(@phone.id)
    assert Session.exists?(@laptop.id)
    follow_redirect!
    assert_match "That session has been signed out.", response.body
  end

  test "destroying another user's session returns 404 and deletes nothing" do
    sign_in_as @user
    assert_no_difference -> { Session.count } do
      delete settings_session_path(@foreign)
    end
    assert_response :not_found
    assert Session.exists?(@foreign.id)
  end

  test "destroying the current session through revoke returns 404" do
    sign_in_as @user
    current = @user.sessions.order(:created_at).last
    assert_no_difference -> { Session.count } do
      delete settings_session_path(current)
    end
    assert_response :not_found
  end

  test "sign out of all other sessions keeps the current one" do
    sign_in_as @user
    current_id = @user.sessions.order(:created_at).last.id

    delete others_settings_sessions_path
    assert_redirected_to settings_sessions_path

    assert_equal [ current_id ], @user.sessions.reload.pluck(:id)
    assert Session.exists?(@foreign.id), "other users' sessions are untouched"

    follow_redirect!
    assert_response :success, "the current session still works"
    assert_match "All other sessions have been signed out.", response.body
  end

  test "a revoked session can no longer access the app" do
    other_device = open_session
    other_device.post session_url, params: { email_address: @user.email_address, password: valid_password }
    other_device.get settings_sessions_path
    other_device.assert_response :success

    sign_in_as @user
    delete others_settings_sessions_path

    other_device.get settings_sessions_path
    other_device.assert_redirected_to new_session_path
  end

  test "after confirming sudo the user returns to the sessions page" do
    sign_in_as @user
    travel 16.minutes

    delete others_settings_sessions_path
    follow_redirect!
    assert_select "input[name=return_to][value=?]", settings_sessions_path
    post sudo_path, params: { password: valid_password, return_to: settings_sessions_path }
    assert_redirected_to settings_sessions_path

    delete others_settings_sessions_path
    assert_redirected_to settings_sessions_path
    assert_equal 1, @user.sessions.count
  end

  test "revoking one session without recent sudo redirects to the sudo form" do
    sign_in_as @user
    travel 16.minutes

    assert_no_difference -> { Session.count } do
      delete settings_session_path(@phone)
    end
    assert_redirected_to new_sudo_path(return_to: settings_sessions_path)
  end

  test "signing out all others without recent sudo redirects to the sudo form" do
    sign_in_as @user
    travel 16.minutes

    get settings_sessions_path
    assert_response :success, "viewing sessions does not require sudo"

    assert_no_difference -> { Session.count } do
      delete others_settings_sessions_path
    end
    assert_redirected_to new_sudo_path(return_to: settings_sessions_path)
  end
end
