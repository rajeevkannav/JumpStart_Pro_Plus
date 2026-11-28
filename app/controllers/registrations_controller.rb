class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

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
      redirect_to root_path, notice: "Welcome! You have signed up successfully. Please check your email to confirm your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
