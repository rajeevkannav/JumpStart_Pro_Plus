require "test_helper"

class Accounts::OwnershipTransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @member = users(:two)
    @acme = accounts(:acme)
    @acme.account_users.create!(user: @member, role: "member")
  end

  def sign_in_to_acme(user)
    sign_in_as user
    post account_switch_path(@acme)
  end

  test "requires sign in" do
    get new_account_ownership_transfer_path
    assert_redirected_to new_session_path

    post account_ownership_transfer_path, params: { user_id: @member.id }
    assert_redirected_to new_session_path
    assert_equal @owner, @acme.reload.owner
  end

  test "owner sees the other members to choose from" do
    sign_in_to_acme @owner

    get new_account_ownership_transfer_path
    assert_response :success
    assert_select "h1", "Transfer ownership"
    assert_select "label", "New owner"
    assert_select "option[value=?]", @member.id.to_s, text: "two@example.com"
    assert_select "option[value=?]", @owner.id.to_s, count: 0
  end

  test "owner transfers ownership to a member" do
    sign_in_to_acme @owner

    post account_ownership_transfer_path, params: { user_id: @member.id }
    assert_redirected_to account_members_path
    assert_equal "two@example.com now owns Acme. You're a member.", flash[:notice]

    @acme.reload
    assert_equal @member, @acme.owner
    assert_equal "owner", @acme.role_for(@member)
    assert_equal "member", @acme.role_for(@owner)

    # The previous owner has lost owner-only screens.
    get new_account_ownership_transfer_path
    assert_response :not_found
    get account_invitations_path
    assert_response :not_found
  end

  test "requires recent sudo" do
    sign_in_to_acme @owner
    travel 16.minutes

    get new_account_ownership_transfer_path
    assert_redirected_to new_sudo_path(return_to: new_account_ownership_transfer_path)

    post account_ownership_transfer_path, params: { user_id: @member.id }
    assert_redirected_to new_sudo_path(return_to: new_account_ownership_transfer_path)
    assert_equal @owner, @acme.reload.owner

    post sudo_path, params: { password: valid_password, return_to: new_account_ownership_transfer_path }
    assert_redirected_to new_account_ownership_transfer_path

    post account_ownership_transfer_path, params: { user_id: @member.id }
    assert_redirected_to account_members_path
    assert_equal @member, @acme.reload.owner
  end

  test "only to an existing member (404 otherwise)" do
    outsider = User.create!(email_address: "outsider@example.com", password: valid_password)
    sign_in_to_acme @owner

    [ outsider.id, @owner.id, User.maximum(:id).to_i + 1000 ].each do |user_id|
      post account_ownership_transfer_path, params: { user_id: user_id }
      assert_response :not_found
    end

    @acme.reload
    assert_equal @owner, @acme.owner
    assert_equal "owner", @acme.role_for(@owner)
  end

  test "members can't transfer ownership (404)" do
    sign_in_to_acme @member

    get new_account_ownership_transfer_path
    assert_response :not_found

    post account_ownership_transfer_path, params: { user_id: @member.id }
    assert_response :not_found
    assert_equal @owner, @acme.reload.owner
  end

  test "members get 404 rather than a sudo prompt" do
    sign_in_to_acme @member
    travel 16.minutes

    post account_ownership_transfer_path, params: { user_id: @member.id }
    assert_response :not_found
  end

  test "personal accounts can't be transferred" do
    sign_in_as @owner

    get new_account_ownership_transfer_path
    assert_redirected_to current_account_path
  end

  test "explains when there is nobody to transfer to" do
    @acme.account_users.where(user: @member).destroy_all
    sign_in_to_acme @owner

    get new_account_ownership_transfer_path
    assert_response :success
    assert_match "nobody else in this account", response.body
    assert_select "select", count: 0
  end

  test "a business-rule failure re-renders the form" do
    (Account::TEAM_ACCOUNT_LIMIT - 1).times { |i| Account.create!(name: "Team #{i}", owner: @member) }
    sign_in_to_acme @owner

    post account_ownership_transfer_path, params: { user_id: @member.id }
    assert_response :unprocessable_entity
    assert_match "already owns", response.body
    assert_equal @owner, @acme.reload.owner
  end
end
