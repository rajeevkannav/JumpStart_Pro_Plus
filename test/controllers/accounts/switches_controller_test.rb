require "test_helper"

class Accounts::SwitchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @acme = accounts(:acme)
    @globex = accounts(:globex)
  end

  test "requires sign in" do
    post account_switch_path(@acme)
    assert_redirected_to new_session_path
  end

  test "switches to an account the user belongs to" do
    sign_in_as @user
    post account_switch_path(@acme)

    assert_redirected_to current_account_path
    assert_equal @acme, latest_session.reload.account
    follow_redirect!
    assert_select "h1", "Acme"
    assert_match "Switched to Acme.", response.body
  end

  test "a member (not owner) can switch too" do
    @acme.account_users.create!(user: users(:two))
    sign_in_as users(:two)
    post account_switch_path(@acme)

    assert_redirected_to current_account_path
    assert_equal @acme, latest_session.reload.account
  end

  test "switching to an account the user isn't a member of is a 404 and keeps the current account" do
    sign_in_as @user
    post account_switch_path(@acme)

    post account_switch_path(@globex)
    assert_response :not_found
    assert_equal @acme, latest_session.reload.account

    get current_account_path
    assert_select "h1", "Acme"
    assert_no_match "Globex", response.body
  end

  test "an unknown account id is a 404" do
    sign_in_as @user
    post account_switch_path(account_id: Account.maximum(:id).to_i + 1000)
    assert_response :not_found
    assert_nil latest_session.reload.account_id
  end

  private
    def latest_session
      Session.order(:created_at, :id).last
    end
end
