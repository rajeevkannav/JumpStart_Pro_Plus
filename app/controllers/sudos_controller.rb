class SudosController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_sudo_path(return_to: safe_return_to(params[:return_to])), alert: "Try again later."
  }

  def new
    @return_to = safe_return_to(params[:return_to])
  end

  def create
    @return_to = safe_return_to(params[:return_to])

    if Current.user.authenticate(params[:password].to_s)
      Current.session.sudo!
      redirect_to @return_to || root_path, notice: "Password confirmed."
    else
      flash.now[:alert] = "That password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end
end
