# Resolves Current.account for signed-in requests. The account id kept in
# the session is only ever looked up through Current.user.accounts, so a
# tampered or stale id falls back to the user's personal account instead of
# exposing another tenant.
module SetCurrentAccount
  extend ActiveSupport::Concern

  included do
    before_action :set_current_account
  end

  private
    def set_current_account
      return unless authenticated?

      Current.account = current_account_from_session || Current.user.personal_account
    end

    def current_account_from_session
      Current.user.accounts.find_by(id: session[:current_account_id]) if session[:current_account_id]
    end
end
