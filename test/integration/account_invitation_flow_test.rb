require "test_helper"

class AccountInvitationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @acme = accounts(:acme)
  end

  def invite(email)
    @acme.invitations.create!(email_address: email, invited_by: @owner)
  end

  test "an owner invites an email and the signed-in invitee accepts and becomes a member" do
    sign_in_as @owner
    post account_switch_path(@acme)
    post account_invitations_path, params: { account_invitation: { email_address: "two@example.com" } }
    invitation = @acme.invitations.find_by!(email_address: "two@example.com")
    delete session_path

    invitee = users(:two)
    sign_in_as invitee
    get invitation_acceptance_path(invitation.token)

    assert_redirected_to current_account_path
    assert_equal "member", @acme.role_for(invitee)
    assert invitation.reload.accepted?

    follow_redirect!
    assert_select "h1", "Acme"

    # The invitation can't be reused.
    get invitation_acceptance_path(invitation.token)
    assert_response :not_found
    assert_select "h1", "This invitation can't be used"
  end

  test "a signed-out invitee signs in and comes back to accept" do
    invitation = invite("two@example.com")

    get invitation_acceptance_path(invitation.token)
    assert_response :success
    assert_select "h1", "Join Acme"
    assert_select "a[href=?]", new_session_path, text: "Sign in"
    assert_select "a[href=?]", new_registration_path, text: "Sign up"
    assert_not invitation.reload.accepted?

    sign_in_as users(:two)
    assert_redirected_to invitation_acceptance_url(invitation.token)
    follow_redirect!

    assert_redirected_to current_account_path
    assert_equal "member", @acme.role_for(users(:two))
  end

  test "a signed-out invitee signs up and comes back to accept" do
    invitation = invite("newbie@example.com")

    get invitation_acceptance_path(invitation.token)
    post registration_path, params: { user: { email_address: "newbie@example.com", password: valid_password, password_confirmation: valid_password } }
    assert_redirected_to invitation_acceptance_url(invitation.token)
    follow_redirect!

    newbie = User.find_by!(email_address: "newbie@example.com")
    assert_redirected_to current_account_path
    assert_equal "member", @acme.role_for(newbie)
  end

  test "a signed-in user with a different email can't accept" do
    invitation = invite("someone-else@example.com")
    sign_in_as users(:two)

    assert_no_difference -> { AccountUser.count } do
      get invitation_acceptance_path(invitation.token)
    end
    assert_response :forbidden
    assert_not invitation.reload.accepted?
  end

  test "expired invitations can't be accepted" do
    invitation = invite("two@example.com")
    invitation.update_columns(expires_at: 1.minute.ago)
    sign_in_as users(:two)

    assert_no_difference -> { AccountUser.count } do
      get invitation_acceptance_path(invitation.token)
    end
    assert_response :not_found
  end

  test "revoked invitations can't be accepted" do
    invitation = invite("two@example.com")
    sign_in_as @owner
    post account_switch_path(@acme)
    delete account_invitation_path(invitation)
    delete session_path

    sign_in_as users(:two)
    assert_no_difference -> { AccountUser.count } do
      get invitation_acceptance_path(invitation.token)
    end
    assert_response :not_found
  end

  test "unknown tokens are a 404, signed in or out" do
    get invitation_acceptance_path("not-a-real-token")
    assert_response :not_found

    sign_in_as users(:two)
    get invitation_acceptance_path("not-a-real-token")
    assert_response :not_found
  end
end
