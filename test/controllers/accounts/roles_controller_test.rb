require "test_helper"

class Accounts::RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @acme = accounts(:acme)
    @admin = User.create!(email_address: "admin@example.com", password: valid_password)
    @member = User.create!(email_address: "member@example.com", password: valid_password)
    @admin_membership = @acme.account_users.create!(user: @admin, role: "admin")
    @member_membership = @acme.account_users.create!(user: @member, role: "member")
  end

  def sign_in_to_acme(user)
    sign_in_as user
    post account_switch_path(@acme)
  end

  test "requires sign in" do
    patch account_member_role_path(@member_membership), params: { role: "admin" }
    assert_redirected_to new_session_path
    assert_equal "member", @member_membership.reload.role
  end

  test "the owner promotes a member to admin" do
    sign_in_to_acme @owner

    patch account_member_role_path(@member_membership), params: { role: "admin" }
    assert_redirected_to account_members_path
    assert_equal "member@example.com is now an admin.", flash[:notice]
    assert_equal "admin", @member_membership.reload.role
  end

  test "the owner demotes an admin to member" do
    sign_in_to_acme @owner

    patch account_member_role_path(@admin_membership), params: { role: "member" }
    assert_redirected_to account_members_path
    assert_equal "admin@example.com is now a member.", flash[:notice]
    assert_equal "member", @admin_membership.reload.role
  end

  test "the owner sees a role form for everyone but themselves" do
    sign_in_to_acme @owner

    get account_members_path
    assert_response :success
    assert_select "form[action=?]", account_member_role_path(@admin_membership)
    assert_select "form[action=?]", account_member_role_path(@member_membership)
    assert_select "form[action=?]", account_member_role_path(account_users(:acme_owner)), count: 0
    assert_select "select[aria-label=?] option", "Role for member@example.com" do |options|
      assert_equal %w[ member admin ], options.map { |option| option["value"] }
    end
  end

  test "a role can never be set to owner" do
    sign_in_to_acme @owner

    patch account_member_role_path(@member_membership), params: { role: "owner" }
    assert_redirected_to account_members_path
    assert_equal "Choose member or admin.", flash[:alert]
    assert_equal "member", @member_membership.reload.role
    assert_equal @owner, @acme.reload.owner
  end

  test "unknown roles are rejected" do
    sign_in_to_acme @owner

    patch account_member_role_path(@member_membership), params: { role: "superuser" }
    assert_redirected_to account_members_path
    assert_equal "member", @member_membership.reload.role
  end

  test "a missing role is a bad request" do
    sign_in_to_acme @owner

    patch account_member_role_path(@member_membership)
    assert_response :bad_request
    assert_equal "member", @member_membership.reload.role
  end

  test "the owner can't change their own role" do
    sign_in_to_acme @owner

    patch account_member_role_path(account_users(:acme_owner)), params: { role: "member" }
    assert_redirected_to account_members_path
    assert_match "Transfer ownership instead", flash[:alert]
    assert_equal "owner", account_users(:acme_owner).reload.role
    assert_equal @owner, @acme.reload.owner
  end

  test "admins and members can't change roles (404)" do
    [ @admin, @member ].each do |user|
      sign_in_to_acme user

      [ @member_membership, @admin_membership, account_users(:acme_owner) ].each do |membership|
        original = membership.reload.role
        patch account_member_role_path(membership), params: { role: "admin" }
        assert_response :not_found
        assert_equal original, membership.reload.role
      end

      delete session_path
    end
  end

  test "admins and members don't see role forms" do
    [ @admin, @member ].each do |user|
      sign_in_to_acme user
      get account_members_path
      assert_response :success
      assert_select "input[type=submit][value=?]", "Change role", count: 0
      delete session_path
    end
  end

  test "another tenant's membership is a 404" do
    globex_member = accounts(:globex).account_users.create!(user: @member, role: "member")
    sign_in_to_acme @owner

    patch account_member_role_path(globex_member), params: { role: "admin" }
    assert_response :not_found
    assert_equal "member", globex_member.reload.role

    patch account_member_role_path(account_users(:globex_owner)), params: { role: "member" }
    assert_response :not_found
    assert_equal "owner", account_users(:globex_owner).reload.role
  end
end
