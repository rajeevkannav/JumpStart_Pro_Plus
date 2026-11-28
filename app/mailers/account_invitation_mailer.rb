class AccountInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @account_name = invitation.account.name
    @inviter_email = invitation.invited_by.email_address
    @url = invitation_acceptance_url(token: invitation.token)

    mail to: invitation.email_address, subject: "You've been invited to join #{@account_name} on JumpStart Pro Plus"
  end
end
