require "test_helper"

class Accounts::MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @member = users(:two)
    @acme = accounts(:acme)
    @membership = @acme.account_users.create!(user: @member, role: "member")
  end

  def sign_in_to_acme(user)
    sign_in_as user
    post account_switch_path(@acme)
  end

  test "requires sign in" do
    get account_members_path
    assert_redirected_to new_session_path

    assert_no_difference -> { AccountUser.count } do
      delete account_member_path(@membership)
    end
    assert_redirected_to new_session_path
  end

  test "owner sees members with remove buttons for others" do
    sign_in_to_acme @owner

    get account_members_path
    assert_response :success
    assert_select "h1", "Members"
    assert_match "one@example.com", response.body
    assert_match "two@example.com", response.body
    assert_select "button", text: "Remove", count: 1
    assert_select "button[aria-label=?]", "Remove two@example.com"
    assert_select "a[href=?]", new_account_ownership_transfer_path, text: "Transfer ownership"
    assert_select "button", text: "Leave this account", count: 0
  end

  test "members see the list and can leave, but can't remove anyone" do
    sign_in_to_acme @member

    get account_members_path
    assert_response :success
    assert_match "one@example.com", response.body
    assert_select "button", text: "Remove", count: 0
    assert_select "a", text: "Transfer ownership", count: 0
    assert_select "button", text: "Leave this account"
  end

  test "the account page links to members" do
    sign_in_to_acme @member
    get current_account_path
    assert_select "a[href=?]", account_members_path, text: "Manage members"
  end

  test "owner removes a member" do
    sign_in_to_acme @owner

    assert_difference -> { @acme.account_users.count }, -1 do
      delete account_member_path(@membership)
    end
    assert_redirected_to account_members_path
    assert_equal "Removed two@example.com from Acme.", flash[:notice]
    assert_not @acme.users.include?(@member)
  end

  test "owner can't remove themselves" do
    sign_in_to_acme @owner

    assert_no_difference -> { AccountUser.count } do
      delete account_member_path(account_users(:acme_owner))
    end
    assert_redirected_to account_members_path
    assert_match "Transfer ownership first", flash[:alert]
  end

  test "a member can't remove others (404)" do
    third = User.create!(email_address: "three@example.com", password: valid_password)
    third_membership = @acme.account_users.create!(user: third, role: "member")
    sign_in_to_acme @member

    [ third_membership, account_users(:acme_owner) ].each do |membership|
      assert_no_difference -> { AccountUser.count } do
        delete account_member_path(membership)
      end
      assert_response :not_found
    end
  end

  test "a member leaves and falls back to their personal account" do
    sign_in_to_acme @member

    assert_difference -> { @acme.account_users.count }, -1 do
      delete account_member_path(@membership)
    end
    assert_redirected_to current_account_path
    assert_equal "You left Acme.", flash[:notice]

    follow_redirect!
    assert_select "h1", "two@example.com"
    assert_nil @member.sessions.order(:created_at, :id).last.account_id

    get account_path(@acme)
    assert_response :not_found
  end

  test "nobody can leave their personal account" do
    sign_in_as @member

    assert_no_difference -> { AccountUser.count } do
      delete account_member_path(account_users(:two_personal_owner))
    end
    assert_redirected_to account_members_path
  end

  test "an unknown membership id is a 404" do
    sign_in_to_acme @owner
    delete account_member_path(id: AccountUser.maximum(:id).to_i + 1000)
    assert_response :not_found
  end
end
