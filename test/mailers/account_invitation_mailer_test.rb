require "test_helper"

class AccountInvitationMailerTest < ActionMailer::TestCase
  test "invite has text and HTML parts with the acceptance link" do
    invitation = accounts(:acme).invitations.create!(email_address: "new@example.com", invited_by: users(:one))
    mail = AccountInvitationMailer.invite(invitation)

    assert_equal [ "new@example.com" ], mail.to
    assert_match "Acme", mail.subject
    url = "http://example.com/invitations/#{invitation.token}"
    assert_match url, mail.text_part.body.to_s
    assert_match url, mail.html_part.body.to_s
    assert_match "one@example.com", mail.text_part.body.to_s
  end
end
