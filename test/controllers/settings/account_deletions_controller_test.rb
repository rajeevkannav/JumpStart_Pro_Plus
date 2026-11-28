require "test_helper"

class Settings::AccountDeletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "requires sign in" do
    get settings_new_account_deletion_path
    assert_redirected_to new_session_path

    post settings_account_deletion_path, params: { confirmation: "DELETE" }
    assert_redirected_to new_session_path
    assert_nil @user.reload.deleted_at
  end

  test "routes live under /settings/account/delete" do
    assert_equal "/settings/account/delete", settings_new_account_deletion_path
    assert_equal "/settings/account/delete", settings_account_deletion_path
  end

  test "new shows the confirmation form" do
    sign_in_as @user
    get settings_new_account_deletion_path

    assert_response :success
    assert_select "h1", "Delete your account"
    assert_select "label", "Type DELETE to confirm"
    assert_select "input[name=confirmation]"
  end

  test "sessions page links to account deletion" do
    sign_in_as @user
    get settings_sessions_path
    assert_select "a[href=?]", settings_new_account_deletion_path, text: "Delete my account"
  end

  test "typing DELETE soft deletes the account, signs out and shows a notice" do
    sign_in_as @user
    other_device = open_session
    other_device.post session_url, params: { email_address: @user.email_address, password: "password123456" }

    post settings_account_deletion_path, params: { confirmation: "DELETE" }

    assert_redirected_to new_session_path
    @user.reload
    assert @user.deleted?
    assert_equal "deleted-#{@user.id}@invalid", @user.email_address
    assert_equal 0, @user.sessions.count
    assert User.exists?(@user.id), "the row is kept for a later purge"

    follow_redirect!
    assert_match "Your account has been deleted.", response.body

    get settings_sessions_path
    assert_redirected_to new_session_path, "this browser is signed out"

    other_device.get settings_sessions_path
    other_device.assert_redirected_to new_session_path
  end

  test "deleting does not touch other users" do
    sign_in_as @user
    post settings_account_deletion_path, params: { confirmation: "DELETE" }

    @other_user.reload
    assert_not @other_user.deleted?
    assert_equal "two@example.com", @other_user.email_address
  end

  test "wrong confirmation text does not delete" do
    sign_in_as @user

    [ "", "delete", "DELETE ME", "yes" ].each do |text|
      post settings_account_deletion_path, params: { confirmation: text }
      assert_response :unprocessable_entity
      assert_match "Type DELETE to confirm.", response.body
    end

    post settings_account_deletion_path
    assert_response :unprocessable_entity

    assert_not @user.reload.deleted?
    assert_equal "one@example.com", @user.email_address
  end

  test "requires sudo to view the form and to delete" do
    sign_in_as @user
    travel 16.minutes

    get settings_new_account_deletion_path
    assert_redirected_to new_sudo_path(return_to: settings_new_account_deletion_path)

    post settings_account_deletion_path, params: { confirmation: "DELETE" }
    assert_redirected_to new_sudo_path(return_to: settings_new_account_deletion_path)
    assert_not @user.reload.deleted?

    post sudo_path, params: { password: "password123456", return_to: settings_new_account_deletion_path }
    assert_redirected_to settings_new_account_deletion_path

    post settings_account_deletion_path, params: { confirmation: "DELETE" }
    assert_redirected_to new_session_path
    assert @user.reload.deleted?
  end

  test "deleted user cannot sign in with the old credentials" do
    sign_in_as @user
    post settings_account_deletion_path, params: { confirmation: "DELETE" }

    post session_url, params: { email_address: "one@example.com", password: "password123456" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_match "Try another email address or password.", response.body

    get settings_sessions_path
    assert_redirected_to new_session_path
  end

  test "the original email can sign up again" do
    sign_in_as @user
    post settings_account_deletion_path, params: { confirmation: "DELETE" }

    assert_difference -> { User.count }, 1 do
      post registration_path, params: { user: { email_address: "one@example.com", password: "brandnewpass123", password_confirmation: "brandnewpass123" } }
    end
    assert_redirected_to root_path
    new_user = User.find_by(email_address: "one@example.com")
    assert_not_equal @user.id, new_user.id
    assert_not new_user.deleted?
  end
end
