# GET /staff — app-wide totals for staff. This is not tenant data: it
# deliberately spans every account, so it's gated on the global staff flag
# (RequireStaff) and only shows counts plus the newest users' emails.
module Staff
  class DashboardController < ApplicationController
    require_staff

    RECENT_USERS_LIMIT = 20

    def show
      @user_count = User.active.count
      @personal_account_count = Account.where(personal: true).count
      @team_account_count = Account.where(personal: false).count
      @pending_invitation_count = AccountInvitation.pending.count
      @recent_users = User.active.order(created_at: :desc, id: :desc).limit(RECENT_USERS_LIMIT)
    end
  end
end
