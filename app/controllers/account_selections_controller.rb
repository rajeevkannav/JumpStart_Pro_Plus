# Selects the account this session works in (sessions.account_id). The id
# is looked up through Current.user.accounts, so selecting an account the
# user doesn't belong to is a 404 and leaves the selection unchanged.
class AccountSelectionsController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :create, with: -> {
    redirect_to accounts_path, alert: "Try again later."
  }

  def create
    account = Current.user.accounts.find(params.require(:account_id))
    Current.session.update!(account: account)
    Current.account = account

    redirect_to current_account_path, notice: "Switched to #{account.name}."
  end
end
