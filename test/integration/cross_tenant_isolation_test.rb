require "test_helper"

# A member of account A must never read, change or list account B's records.
# Foreign ids return 404 (not 403) so their existence isn't leaked.
class CrossTenantIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @foreign_accounts = [ accounts(:globex), accounts(:two_personal) ]
    sign_in_as @user
  end

  test "cannot list another tenant's accounts" do
    get accounts_path
    assert_response :success
    assert_no_match "Globex", response.body
    assert_no_match "two@example.com", response.body
  end

  test "cannot read another tenant's account" do
    @foreign_accounts.each do |account|
      get account_path(account)
      assert_response :not_found

      get edit_account_path(account)
      assert_response :not_found
    end
  end

  test "cannot change another tenant's account" do
    @foreign_accounts.each do |account|
      patch account_path(account), params: { account: { name: "Hijacked" } }
      assert_response :not_found
      assert_not_equal "Hijacked", account.reload.name
    end
  end

  test "cannot delete another tenant's account" do
    @foreign_accounts.each do |account|
      assert_no_difference -> { Account.count } do
        delete account_path(account)
      end
      assert_response :not_found
    end
  end

  test "an unknown id is a 404 too" do
    get account_path(id: Account.maximum(:id).to_i + 1000)
    assert_response :not_found
  end

  test "Current.account defaults to the user's personal account" do
    get accounts_path
    assert_select "li", text: /one@example\.com.*Current/m
  end
end
