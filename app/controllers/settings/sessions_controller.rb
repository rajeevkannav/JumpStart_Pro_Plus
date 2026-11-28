module Settings
  # Lists where the current user is signed in and lets them revoke other
  # sessions. Everything is scoped through Current.user, so another user's
  # session id raises RecordNotFound (404).
  class SessionsController < ApplicationController
    require_sudo only: %i[ destroy destroy_others ]

    def index
      @sessions = Current.user.sessions.order(created_at: :desc)
    end

    def destroy
      other_sessions.find(params[:id]).destroy
      redirect_to settings_sessions_path, notice: "That session has been signed out."
    end

    def destroy_others
      other_sessions.destroy_all
      redirect_to settings_sessions_path, notice: "All other sessions have been signed out."
    end

    private
      def sudo_return_to
        settings_sessions_path
      end

      def other_sessions
        Current.user.sessions.where.not(id: Current.session.id)
      end
  end
end
