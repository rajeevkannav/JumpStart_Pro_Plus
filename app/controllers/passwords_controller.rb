class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]

  rate_limit to: 5, within: 15.minutes, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_password_path, alert: "Try again later." }
      format.json { render json: { error: "Try again later." }, status: :too_many_requests }
    end
  }

  def new
  end

  def create
    if user = User.active.find_by(email_address: params[:email_address])
      begin
        PasswordsMailer.reset(user).deliver_later
      rescue => e
        Rails.logger.error "Failed to send password reset email: #{e.class}"
      end
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.active.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
