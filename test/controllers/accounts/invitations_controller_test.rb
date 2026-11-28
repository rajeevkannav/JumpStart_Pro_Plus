require "test_helper"

class Accounts::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @acme = accounts(:acme)
    ActionMailer::Base.deliveries.clear
  end

  def sign_in_to_acme
    sign_in_as @owner
    post account_switch_path(@acme)
  end

  test "requires sign in" do
    get account_invitations_path
    assert_redirected_to new_session_path

    assert_no_difference -> { AccountInvitation.count } do
      post account_invitations_path, params: { account_invitation: { email_address: "new@example.com" } }
    end
    assert_redirected_to new_session_path
  end

  test "owner sees the invite form and pending invitations" do
    sign_in_to_acme
    @acme.invitations.create!(email_address: "pending@example.com", invited_by: @owner)

    get account_invitations_path
    assert_response :success
    assert_select "h1", "Invitations"
    assert_match "pending@example.com", response.body

    get new_account_invitation_path
    assert_response :success
    assert_select "label", "Email address"
  end

  test "the account page links owners to invitations" do
    sign_in_to_acme
    get current_account_path
    assert_select "a[href=?]", account_invitations_path, text: "Invite members"
  end

  test "owner invites an email and an invitation email is sent" do
    sign_in_to_acme

    assert_difference -> { @acme.invitations.count }, 1 do
      post account_invitations_path, params: { account_invitation: { email_address: "New@Example.com" } }
    end
    assert_redirected_to account_invitations_path
    assert_equal "Invitation sent to new@example.com.", flash[:notice]

    invitation = @acme.invitations.last
    assert_equal "new@example.com", invitation.email_address
    assert_equal @owner, invitation.invited_by

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "new@example.com" ], mail.to
    assert_match invitation_acceptance_path(token: invitation.token), mail.text_part.body.to_s
  end

  test "invalid email re-renders the form" do
    sign_in_to_acme

    assert_no_difference -> { AccountInvitation.count } do
      post account_invitations_path, params: { account_invitation: { email_address: "nope" } }
    end
    assert_response :unprocessable_entity
    assert_select "#error_explanation"
  end

  test "mail failures don't fail the request" do
    sign_in_to_acme
    AccountInvitationMailer.define_singleton_method(:invite) { |_invitation| raise StandardError, "SMTP down" }

    begin
      assert_difference -> { AccountInvitation.count }, 1 do
        post account_invitations_path, params: { account_invitation: { email_address: "new@example.com" } }
      end
      assert_redirected_to account_invitations_path
    ensure
      AccountInvitationMailer.singleton_class.send(:remove_method, :invite)
    end
  end

  test "owner revokes a pending invitation" do
    sign_in_to_acme
    invitation = @acme.invitations.create!(email_address: "pending@example.com", invited_by: @owner)

    assert_difference -> { AccountInvitation.count }, -1 do
      delete account_invitation_path(invitation)
    end
    assert_redirected_to account_invitations_path
  end

  test "members who aren't the owner get 404" do
    member = users(:two)
    @acme.account_users.create!(user: member, role: "member")
    invitation = @acme.invitations.create!(email_address: "pending@example.com", invited_by: @owner)

    sign_in_as member
    post account_switch_path(@acme)

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

    get current_account_path
    assert_select "a", text: "Invite members", count: 0
  end

  test "personal accounts can't invite" do
    sign_in_as @owner # works in the personal account by default

    get account_invitations_path
    assert_redirected_to current_account_path

    assert_no_difference -> { AccountInvitation.count } do
      post account_invitations_path, params: { account_invitation: { email_address: "new@example.com" } }
    end
    assert_redirected_to current_account_path
  end

  test "invitation creation is rate limited to 20 per hour per user" do
    sign_in_to_acme

    20.times do |i|
      post account_invitations_path, params: { account_invitation: { email_address: "person#{i}@example.com" } }
      assert_redirected_to account_invitations_path
      assert_nil flash[:alert]
    end

    assert_no_difference -> { AccountInvitation.count } do
      post account_invitations_path, params: { account_invitation: { email_address: "one-too-many@example.com" } }
    end
    assert_redirected_to account_invitations_path
    assert_match "Try again later", flash[:alert]
  end
end
