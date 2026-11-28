# The owner of Current.account switches a member between "member" and
# "admin".
#
#   PATCH /account/members/:member_id/role   role=member|admin
#
# Owners only (admins and members get a 404). The membership is loaded
# through Current.account.account_users, so another tenant's id is a 404.
# The owner's own role can't change here and "owner" is never accepted:
# handing over the account is the ownership transfer.
module Accounts
  class RolesController < ApplicationController
    include AccountScoped

    require_account_role :owner
    rate_limit to: 30, within: 1.minute, only: :update, with: -> {
      redirect_to account_members_path, alert: "Try again later."
    }

    def update
      membership = Current.account.account_users.find(params[:member_id])
      Current.account.change_role!(membership, params.require(:role))

      redirect_to account_members_path, notice: "#{membership.user.email_address} is now #{membership.role == "admin" ? "an admin" : "a member"}."
    rescue Account::MembershipError => e
      redirect_to account_members_path, alert: e.message
    end
  end
end
