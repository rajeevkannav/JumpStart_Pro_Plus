class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access only: %i[ show ]
  before_action :require_authentication, only: %i[ create ]

  rate_limit to: 3, within: 10.minutes, only: :create, by: -> { Current.user&.id || request.remote_ip }, with: -> {
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Try again later." }
      format.json { render json: { error: "Try again later." }, status: :too_many_requests }
    end
  }

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
