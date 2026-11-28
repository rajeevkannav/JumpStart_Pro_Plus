require "test_helper"

class SudosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @session = @user.sessions.order(:created_at).last
  end

  test "sign-in sets sudo_at" do
    assert_not_nil @session.sudo_at
    assert @session.sudo?
  end

  test "new requires authentication" do
    delete session_path
    get new_sudo_path
    assert_redirected_to new_session_path
  end

  test "new renders the password form with the return path" do
    get new_sudo_path(return_to: "/settings")
    assert_response :success
    assert_select "h1", "Confirm your password"
    assert_select "input[type=password][name=password]"
    assert_select "input[type=hidden][name=return_to][value=?]", "/settings"
  end

  test "new drops an external return_to" do
    get new_sudo_path(return_to: "https://evil.example.com/phish")
    assert_response :success
    assert_select "input[name=return_to]", false
  end

  test "correct password updates sudo_at and redirects to return_to" do
    travel 20.minutes
    assert_not @session.reload.sudo?

    post sudo_path, params: { password: valid_password, return_to: "/settings?tab=security" }

    assert_redirected_to "/settings?tab=security"
    assert @session.reload.sudo?
    assert_in_delta Time.current, @session.sudo_at, 1.second
  end

  test "correct password without return_to redirects to root" do
    post sudo_path, params: { password: valid_password }
    assert_redirected_to root_path
  end

  test "external and protocol-relative return_to URLs are ignored" do
    [
      "https://evil.example.com/",
      "//evil.example.com/",
      "/\\evil.example.com",
      "javascript:alert(1)",
      "evil.example.com",
      "/path\r\nLocation: https://evil.example.com"
    ].each do |target|
      post sudo_path, params: { password: valid_password, return_to: target }
      assert_redirected_to root_path, "expected #{target.inspect} to be ignored"
    end
  end

  test "wrong password re-renders the form with 422 and leaves sudo_at unchanged" do
    travel 20.minutes
    sudo_at_before = @session.reload.sudo_at

    post sudo_path, params: { password: wrong_password, return_to: "/settings" }

    assert_response :unprocessable_entity
    assert_select "h1", "Confirm your password"
    assert_match "That password is incorrect.", response.body
    assert_select "input[type=hidden][name=return_to][value=?]", "/settings"
    assert_equal sudo_at_before, @session.reload.sudo_at
    assert_not @session.sudo?
  end

  test "only updates the current session" do
    other = @user.sessions.create!
    other.update!(sudo_at: 1.hour.ago)
    travel 20.minutes

    post sudo_path, params: { password: valid_password }

    assert @session.reload.sudo?
    assert_not other.reload.sudo?
  end
end
