# Members of Current.account.
#
#   GET    /account/members       everyone in the account sees the list
#   DELETE /account/members/:id   the owner removes a member, or a member
#                                 removes themselves (leaves the account)
#
# Memberships are always loaded through Current.account.account_users, so a
# foreign id is a 404. A member trying to remove someone else is also a 404
# (not 403), so nothing about other memberships is leaked.
module Accounts
  class MembersController < ApplicationController
    include AccountScoped

    rate_limit to: 30, within: 1.minute, only: :destroy, with: -> {
      redirect_to account_members_path, alert: "Try again later."
    }

    def index
      @memberships = Current.account.account_users.includes(:user).order(:created_at, :id)
      @owner = Current.account.owner?(Current.user)
    end

    def destroy
      membership = Current.account.account_users.find(params[:id])
      leaving = membership.user_id == Current.user.id
      raise ActiveRecord::RecordNotFound unless leaving || Current.account.owner?(Current.user)

      account = Current.account
      account.remove_member!(membership)

      if leaving
        Current.account = Current.session.reload.current_account
        redirect_to current_account_path, notice: "You left #{account.name}."
      else
        redirect_to account_members_path, notice: "Removed #{membership.user.email_address} from #{account.name}."
      end
    rescue Account::MembershipError => e
      redirect_to account_members_path, alert: e.message
    end
  end
end
