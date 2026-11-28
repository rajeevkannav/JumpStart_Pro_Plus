require "test_helper"

# Current.account comes from sessions.account_id, resolved only through the
# user's own memberships, and falls back to the personal account.
class CurrentAccountTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @acme = accounts(:acme)
    @globex = accounts(:globex)
  end

  test "requires sign in" do
    get current_account_path
    assert_redirected_to new_session_path

    post account_selection_path, params: { account_id: @acme.id }
    assert_redirected_to new_session_path
  end

  test "/account shows the personal account right after sign-up" do
    post registration_path, params: { user: { email_address: "fresh@example.com", password: valid_password, password_confirmation: valid_password } }

    get current_account_path
    assert_response :success
    assert_select "h1", "fresh@example.com"
    assert_select "dd", "Personal"
    assert_select "dd", "Owner"
    assert_select "dd", "1"
    assert_select "dd", "Current account"
  end

  test "navbar links to the current account" do
    sign_in_as @user
    follow_redirect!
    assert_select "nav a[href=?]", current_account_path, text: "Account"
  end

  test "switching to an account the user belongs to" do
    @acme.account_users.create!(user: users(:two))
    sign_in_as @user

    post account_selection_path, params: { account_id: @acme.id }
    assert_redirected_to current_account_path
    assert_equal @acme, latest_session.account

    follow_redirect!
    assert_select "h1", "Acme"
    assert_select "dd", "Shared"
    assert_select "dd", "Owner"
    assert_select "dd", "2"
  end

  test "a member sees their member role" do
    @acme.account_users.create!(user: users(:two))
    sign_in_as users(:two)
    post account_selection_path, params: { account_id: @acme.id }
    follow_redirect!

    assert_select "h1", "Acme"
    assert_select "dd", "Member"
  end

  test "can't select an account the user doesn't belong to" do
    sign_in_as @user

    post account_selection_path, params: { account_id: @globex.id }
    assert_response :not_found
    assert_nil latest_session.reload.account_id

    get current_account_path
    assert_select "h1", "one@example.com"
    assert_no_match "Globex", response.body
  end

  test "a foreign account id stored in the session falls back to the personal account" do
    sign_in_as @user
    latest_session.update_column(:account_id, @globex.id)

    get current_account_path
    assert_response :success
    assert_select "h1", "one@example.com"
    assert_no_match "Globex", response.body
  end

  test "losing membership falls back to the personal account" do
    @globex.account_users.create!(user: @user)
    sign_in_as @user
    post account_selection_path, params: { account_id: @globex.id }

    @globex.account_users.find_by!(user: @user).destroy!

    get current_account_path
    assert_select "h1", "one@example.com"
  end

  test "deleting the selected account clears the selection" do
    sign_in_as @user
    post account_selection_path, params: { account_id: @acme.id }

    delete account_path(@acme)
    assert_redirected_to accounts_path
    assert_nil latest_session.reload.account_id

    get current_account_path
    assert_select "h1", "one@example.com"
  end

  test "the account selection is per session" do
    sign_in_as @user
    post account_selection_path, params: { account_id: @acme.id }
    first = latest_session

    reset!
    sign_in_as @user
    get current_account_path
    assert_select "h1", "one@example.com"
    assert_equal @acme, first.reload.account
  end

  private
    def latest_session
      Session.order(:created_at, :id).last
    end
end
