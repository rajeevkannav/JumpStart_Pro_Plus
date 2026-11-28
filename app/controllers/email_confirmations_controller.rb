class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access only: %i[ show ]
  before_action :require_authentication, only: %i[ create ]

  def show
    if user = User.find_by_token_for(:email_confirmation, params[:token])
      user.update!(email_confirmed_at: Time.current)
      redirect_to root_path, notice: "Your email has been confirmed."
    else
      redirect_to root_path, alert: "Invalid or expired confirmation link."
    end
  end

  def create
    if Current.user.email_confirmed?
      redirect_to root_path, notice: "Email already confirmed."
    else
      begin
        UserMailer.email_confirmation(Current.user).deliver_later
      rescue => e
        Rails.logger.error "Failed to resend confirmation email: #{e.class}"
      end
      redirect_to root_path, notice: "Confirmation email sent."
    end
  end
end
