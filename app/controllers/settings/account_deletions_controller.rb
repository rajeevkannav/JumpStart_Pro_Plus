module Settings
  # Lets the signed-in user delete their own account. The account is soft
  # deleted (see User#soft_delete!) so it can be purged later. Requires sudo
  # mode and typing DELETE to confirm.
  class AccountDeletionsController < ApplicationController
    CONFIRMATION = "DELETE".freeze

    require_sudo
    rate_limit to: 5, within: 15.minutes, only: :create, with: -> {
      redirect_to settings_new_account_deletion_path, alert: "Try again later."
    }

    def new
    end

    def create
      if params[:confirmation].to_s == CONFIRMATION
        Current.user.soft_delete!
        Current.session = nil
        cookies.delete(:session_id)
        reset_session
        redirect_to new_session_path, notice: "Your account has been deleted."
      else
        flash.now[:alert] = "Type DELETE to confirm."
        render :new, status: :unprocessable_entity
      end
    end

    private
      def sudo_return_to
        settings_new_account_deletion_path
      end
  end
end
