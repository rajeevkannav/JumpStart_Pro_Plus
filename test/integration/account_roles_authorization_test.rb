require "test_helper"

# Who may do what in a team account. Allowed roles succeed; everyone else
# gets a 404 so nothing reveals that the page or record exists.
class AccountRolesAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
    @owner = users(:one)
    @acme = accounts(:acme)
    @admin = User.create!(email_address: "admin@example.com", password: valid_password)
    @member = User.create!(email_address: "member@example.com", password: valid_password)
    @other_admin = User.create!(email_address: "admin2@example.com", password: valid_password)
    @admin_membership = @acme.account_users.create!(user: @admin, role: "admin")
    @member_membership = @acme.account_users.create!(user: @member, role: "member")
    @other_admin_membership = @acme.account_users.create!(user: @other_admin, role: "admin")
  end

  def sign_in_to_acme(user)
    sign_in_as user
    post account_switch_path(@acme)
  end

  # --- Current.account_user / Current.roles -------------------------------

  test "Current exposes the membership and roles for the current account" do
    session = @admin.sessions.create!
    Current.session = session
    Current.account = @acme
    assert_equal @admin_membership, Current.account_user
    assert_equal %i[ admin member ], Current.roles

    Current.account = accounts(:globex)
    assert_nil Current.account_user
    assert_equal [], Current.roles
  ensure
    Current.reset
  end

  test "the owner's roles follow accounts.owner_id" do
    Current.session = @owner.sessions.create!
    Current.account = @acme
    assert_equal %i[ owner admin member ], Current.roles
  ensure
    Current.reset
  end

  # --- Invitations: admins and owners ------------------------------------

  test "admins can list, invite and revoke" do
    sign_in_to_acme @admin

    get account_invitations_path
    assert_response :success
    get new_account_invitation_path
    assert_response :success

    assert_difference -> { @acme.invitations.count }, 1 do
      post account_invitations_path, params: { account_invitation: { email_address: "new@example.com" } }
    end
    assert_redirected_to account_invitations_path
    invitation = @acme.invitations.last
    assert_equal @admin, invitation.invited_by
    assert_equal [ "new@example.com" ], ActionMailer::Base.deliveries.last.to

    assert_difference -> { @acme.invitations.count }, -1 do
      delete account_invitation_path(invitation)
    end
    assert_redirected_to account_invitations_path
  end

  test "members can't use invitations (404)" do
    invitation = @acme.invitations.create!(email_address: "pending@example.com", invited_by: @owner)
    sign_in_to_acme @member

    get account_invitations_path
    assert_response :not_found
    get new_account_invitation_path
    assert_response :not_found

    assert_no_difference -> { AccountInvitation.count } do
      post account_invitations_path, params: { account_invitation: { email_address: "new@example.com" } }
    end
    assert_response :not_found

    assert_no_difference -> { AccountInvitation.count } do
      delete account_invitation_path(invitation)
    end
    assert_response :not_found
  end

  test "the members and account pages offer invitations to admins only" do
    sign_in_to_acme @admin
    get account_members_path
    assert_select "a[href=?]", account_invitations_path, text: "Invite members"
    get current_account_path
    assert_select "a[href=?]", account_invitations_path, text: "Invite members"
    delete session_path

    sign_in_to_acme @member
    get account_members_path
    assert_select "a[href=?]", account_invitations_path, count: 0
    get current_account_path
    assert_select "a[href=?]", account_invitations_path, count: 0
  end

  # --- Member removal: admins remove members; owner removes anyone -------

  test "admins remove plain members" do
    sign_in_to_acme @admin

    get account_members_path
    assert_select "button[aria-label=?]", "Remove member@example.com"
    assert_select "button[aria-label=?]", "Remove admin2@example.com", count: 0
    assert_select "button[aria-label=?]", "Remove one@example.com", count: 0

    assert_difference -> { @acme.account_users.count }, -1 do
      delete account_member_path(@member_membership)
    end
    assert_redirected_to account_members_path
    assert_not @acme.users.include?(@member)
  end

  test "admins can't remove other admins or the owner (404)" do
    sign_in_to_acme @admin

    [ @other_admin_membership, account_users(:acme_owner) ].each do |membership|
      assert_no_difference -> { AccountUser.count } do
        delete account_member_path(membership)
      end
      assert_response :not_found
    end
  end

  test "the owner removes admins" do
    sign_in_to_acme @owner

    assert_difference -> { @acme.account_users.count }, -1 do
      delete account_member_path(@admin_membership)
    end
    assert_redirected_to account_members_path
  end

  test "admins can leave" do
    sign_in_to_acme @admin

    assert_difference -> { @acme.account_users.count }, -1 do
      delete account_member_path(@admin_membership)
    end
    assert_redirected_to current_account_path
  end

  test "members can't remove anyone (404)" do
    sign_in_to_acme @member

    [ @admin_membership, account_users(:acme_owner) ].each do |membership|
      assert_no_difference -> { AccountUser.count } do
        delete account_member_path(membership)
      end
      assert_response :not_found
    end
  end

  # --- Ownership transfer: owner only ------------------------------------

  test "admins can't transfer ownership (404)" do
    sign_in_to_acme @admin

    get account_members_path
    assert_response :success
    assert_select "a", text: "Transfer ownership", count: 0

    get new_account_ownership_transfer_path
    assert_response :not_found

    post account_ownership_transfer_path, params: { user_id: @admin.id }
    assert_response :not_found
    assert_equal @owner, @acme.reload.owner
    assert_equal "admin", @admin_membership.reload.role
  end

  test "a new owner gains owner rights and the old owner loses them" do
    sign_in_to_acme @owner
    post account_ownership_transfer_path, params: { user_id: @admin.id }
    assert_redirected_to account_members_path
    assert_equal @admin, @acme.reload.owner

    patch account_member_role_path(@member_membership), params: { role: "admin" }
    assert_response :not_found
    assert_equal "member", @member_membership.reload.role
  end

  # --- Cross-tenant: roles in A grant nothing in B ------------------------

  test "an admin of one account has no rights in another" do
    globex = accounts(:globex)
    globex_member = globex.account_users.create!(user: @member, role: "member")
    globex_invitation = globex.invitations.create!(email_address: "x@example.com", invited_by: users(:two))
    sign_in_to_acme @admin

    assert_no_difference -> { AccountUser.count } do
      delete account_member_path(globex_member)
    end
    assert_response :not_found

    assert_no_difference -> { AccountInvitation.count } do
      delete account_invitation_path(globex_invitation)
    end
    assert_response :not_found

    post account_switch_path(globex)
    assert_response :not_found
  end
end
