# Resolves Current.account for signed-in requests from the account selected
# in the session (sessions.account_id), falling back to the user's personal
# account. See Session#current_account: the id is only ever looked up through
# Current.user.accounts, so it can never point at another tenant.
#
#   class ProjectsController < ApplicationController
#     require_account
#   end
module SetCurrentAccount
  extend ActiveSupport::Concern

  included do
    before_action :set_current_account
  end

  class_methods do
    def require_account(**options)
      before_action :enforce_account, **options
    end
  end

  private
    def set_current_account
      return unless authenticated?

      Current.account = Current.session.current_account
    end

    def enforce_account
      return if Current.account

      redirect_to accounts_path, alert: "Choose an account first."
    end
end
