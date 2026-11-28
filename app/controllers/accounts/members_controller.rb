# Members of Current.account.
#
#   GET    /account/members       everyone in the account sees the list
#   DELETE /account/members/:id   the owner removes anyone but themselves,
#                                 an admin removes plain members, and anyone
#                                 can remove themselves (leave the account)
#
# Memberships are always loaded through Current.account.account_users, so a
# foreign id is a 404. Removing someone you're not allowed to is also a 404
# (not 403), so nothing about other memberships is leaked.
module Accounts
  class MembersController < ApplicationController
    include AccountScoped

    rate_limit to: 30, within: 1.minute, only: :destroy, with: -> {
      redirect_to account_members_path, alert: "Try again later."
    }

    helper_method :can_remove?

    def index
      @memberships = Current.account.account_users.includes(:user).order(:created_at, :id)
    end

    def destroy
      membership = Current.account.account_users.find(params[:id])
      leaving = membership.user_id == Current.user.id
      raise ActiveRecord::RecordNotFound unless leaving || can_remove?(membership)

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

    private
      # Whether the signed-in user may remove someone else's membership. The
      # owner can't be removed by anyone (see Account#remove_member!).
      def can_remove?(membership)
        return false if membership.user_id == Current.user.id || membership.user_id == Current.account.owner_id
        return true if account_owner?

        account_admin? && membership.role == "member"
      end
  end
end
