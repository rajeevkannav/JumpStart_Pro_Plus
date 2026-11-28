# The owner of Current.account hands it to another existing member.
#
#   GET  /account/ownership_transfer/new   pick the new owner
#   POST /account/ownership_transfer       transfer (user_id of a member)
#
# Owners only (admins and members get a 404), team accounts only, and sudo
# mode is required. The new owner is looked up through Current.account's own
# memberships, so a non-member or another tenant's user is a 404.
module Accounts
  class OwnershipTransfersController < ApplicationController
    include AccountScoped

    require_account_role :owner
    before_action :require_team_account
    require_sudo
    rate_limit to: 10, within: 15.minutes, only: :create, with: -> {
      redirect_to new_account_ownership_transfer_path, alert: "Try again later."
    }

    def new
      @candidates = candidates
    end

    def create
      membership = candidates.find_by!(user_id: params.require(:user_id))
      account = Current.account
      account.transfer_ownership_to!(membership.user)

      redirect_to account_members_path, notice: "#{membership.user.email_address} now owns #{account.name}. You're a member."
    rescue Account::MembershipError => e
      @candidates = candidates
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    private
      def require_team_account
        return unless Current.account.personal?

        redirect_to current_account_path, alert: "Personal accounts can't be transferred."
      end

      def candidates
        Current.account.account_users
          .where.not(user_id: Current.account.owner_id)
          .joins(:user).merge(User.active)
          .includes(:user).order(:created_at, :id)
      end

      def sudo_return_to
        new_account_ownership_transfer_path
      end
  end
end
