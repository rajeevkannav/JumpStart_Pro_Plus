require "test_helper"

# The navbar account switcher lists exactly the signed-in user's accounts.
class AccountSwitcherTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "is not shown when signed out" do
    get root_path
    assert_response :success
    assert_select "#account-switcher", count: 0
  end

  test "shows the current account and lists exactly the user's accounts" do
    sign_in_as @user
    get root_path

    assert_select "#account-switcher summary", text: /one@example\.com/
    assert_select "#account-switcher li", text: /one@example\.com/
    assert_select "#account-switcher li", text: /Acme/
    assert_select "#account-switcher a[href=?]", new_account_path, text: "New team account"

    switch_targets = css_select("#account-switcher form").map { |form| form["action"] }
    assert_equal [ account_switch_path(accounts(:acme)) ], switch_targets
    assert_no_match "Globex", response.body
    assert_no_match "two@example.com", response.body
  end

  test "lists accounts the user was added to and follows the current account" do
    globex = accounts(:globex)
    globex.account_users.create!(user: @user)
    sign_in_as @user

    post account_switch_path(globex)
    follow_redirect!

    assert_select "#account-switcher summary", text: /Globex/
    switch_targets = css_select("#account-switcher form").map { |form| form["action"] }.sort
    expected = [ accounts(:one_personal), accounts(:acme) ].map { |account| account_switch_path(account) }.sort
    assert_equal expected, switch_targets
    assert_select "#account-switcher", text: /two@example\.com/, count: 0
  end

  test "switching from the navbar" do
    sign_in_as @user
    get root_path
    action = css_select("#account-switcher form").first["action"]

    post action
    follow_redirect!
    assert_select "#account-switcher summary", text: /Acme/
  end
end
