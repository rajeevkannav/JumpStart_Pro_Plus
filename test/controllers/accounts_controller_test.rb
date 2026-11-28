require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @acme = accounts(:acme)
    @personal = accounts(:one_personal)
  end

  test "requires sign in" do
    get accounts_path
    assert_redirected_to new_session_path

    get account_path(@acme)
    assert_redirected_to new_session_path

    assert_no_difference -> { Account.count } do
      post accounts_path, params: { account: { name: "Sneaky" } }
    end
    assert_redirected_to new_session_path
  end

  test "index lists the user's accounts" do
    sign_in_as @user
    get accounts_path

    assert_response :success
    assert_select "h1", "Your accounts"
    assert_select "a[href=?]", account_path(@acme), text: "Acme"
    assert_select "a[href=?]", account_path(@personal), text: "one@example.com"
  end

  test "navbar links to accounts when signed in" do
    sign_in_as @user
    follow_redirect!
    assert_select "nav a[href=?]", accounts_path, text: "Accounts"
  end

  test "show lists members" do
    sign_in_as @user
    get account_path(@acme)

    assert_response :success
    assert_select "h1", "Acme"
    assert_match "one@example.com", response.body
    assert_select "button", text: "Delete this account"
  end

  test "personal account page has no delete button" do
    sign_in_as @user
    get account_path(@personal)

    assert_response :success
    assert_select "button", text: "Delete this account", count: 0
  end

  test "create makes the user the owner of a new shared account" do
    sign_in_as @user
    assert_difference -> { Account.count } => 1, -> { AccountUser.count } => 1 do
      post accounts_path, params: { account: { name: "Initech" } }
    end

    account = Account.find_by!(name: "Initech")
    assert_redirected_to account_path(account)
    assert_not account.personal?
    assert account.owner?(@user)
    assert_equal "owner", account.role_for(@user)
  end

  test "create cannot be used to make a personal account or set another owner" do
    sign_in_as @user
    post accounts_path, params: { account: { name: "Initech", personal: true, owner_id: users(:two).id } }

    account = Account.find_by!(name: "Initech")
    assert_not account.personal?
    assert_equal @user, account.owner
  end

  test "create with a blank name re-renders the form" do
    sign_in_as @user
    assert_no_difference -> { Account.count } do
      post accounts_path, params: { account: { name: "" } }
    end
    assert_response :unprocessable_entity
    assert_match "Name can&#39;t be blank", response.body
  end

  test "owner can rename an account" do
    sign_in_as @user
    get edit_account_path(@acme)
    assert_response :success

    patch account_path(@acme), params: { account: { name: "Acme Corp" } }
    assert_redirected_to account_path(@acme)
    assert_equal "Acme Corp", @acme.reload.name
  end

  test "owner can delete a shared account" do
    sign_in_as @user
    assert_difference -> { Account.count }, -1 do
      delete account_path(@acme)
    end
    assert_redirected_to accounts_path
  end

  test "personal accounts can't be deleted" do
    sign_in_as @user
    assert_no_difference -> { Account.count } do
      delete account_path(@personal)
    end
    assert_redirected_to account_path(@personal)
    follow_redirect!
    assert_match "Personal accounts can&#39;t be deleted", response.body
  end

  test "deleting requires sudo" do
    sign_in_as @user
    travel 16.minutes

    assert_no_difference -> { Account.count } do
      delete account_path(@acme)
    end
    assert_redirected_to new_sudo_path(return_to: account_path(@acme))
  end

  test "a member who is not the owner can view but not change the account" do
    @acme.account_users.create!(user: users(:two))
    sign_in_as users(:two)

    get account_path(@acme)
    assert_response :success
    assert_select "a", text: "Edit account", count: 0

    get edit_account_path(@acme)
    assert_response :not_found

    patch account_path(@acme), params: { account: { name: "Hijacked" } }
    assert_response :not_found

    assert_no_difference -> { Account.count } do
      delete account_path(@acme)
    end
    assert_response :not_found
    assert_equal "Acme", @acme.reload.name
  end
end
