class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  rate_limit to: 5, within: 1.hour, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_registration_path, alert: "Try again later." }
      format.json { render json: { error: "Try again later." }, status: :too_many_requests }
    end
  }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      begin
        UserMailer.email_confirmation(@user).deliver_now
      rescue => e
        Rails.logger.error "Failed to send confirmation email: #{e.class}"
      end
      # Back to where sign-up was requested from (e.g. an invitation link).
      redirect_to after_authentication_url, notice: "Welcome! You have signed up successfully. Please check your email to confirm your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
