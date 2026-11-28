class UserMailer < ApplicationMailer
  def email_confirmation(user)
    @user = user
    @token = user.generate_token_for(:email_confirmation)
    mail to: user.email_address, subject: "Confirm your email address"
  end
end
