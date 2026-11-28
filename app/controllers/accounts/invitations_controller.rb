# Invitations to Current.account, managed by its owner.
#
#   GET    /account/invitations       pending invitations
#   GET    /account/invitations/new   invite form
#   POST   /account/invitations       invite an email address
#   DELETE /account/invitations/:id   revoke a pending invitation
#
# Members who aren't the owner get a 404 (not 403). Invitations are always
# loaded through Current.account.invitations, so another tenant's id is a 404.
module Accounts
  class InvitationsController < ApplicationController
    include AccountScoped

    before_action :require_owner
    before_action :require_team_account
    rate_limit to: 20, within: 1.hour, only: :create, by: -> { Current.user.id }, with: -> {
      redirect_to account_invitations_path, alert: "You've sent a lot of invitations. Try again later."
    }

    def index
      @invitations = Current.account.invitations.pending.includes(:invited_by).order(created_at: :desc)
    end

    def new
      @invitation = Current.account.invitations.new
    end

    def create
      @invitation = Current.account.invitations.new(invitation_params.merge(invited_by: Current.user))

      if @invitation.save
        deliver_invitation(@invitation)
        redirect_to account_invitations_path, notice: "Invitation sent to #{@invitation.email_address}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      invitation = Current.account.invitations.unaccepted.find(params[:id])
      invitation.destroy!
      redirect_to account_invitations_path, notice: "Invitation to #{invitation.email_address} revoked."
    end

    private
      def require_owner
        raise ActiveRecord::RecordNotFound unless Current.account.owner?(Current.user)
      end

      def require_team_account
        return unless Current.account.personal?

        redirect_to current_account_path, alert: "Personal accounts can't invite members. Create a team account to work with others."
      end

      def invitation_params
        params.require(:account_invitation).permit(:email_address)
      end

      # Mail problems must never fail the request. Only the error class is
      # logged: never the token, the link or the message body.
      def deliver_invitation(invitation)
        AccountInvitationMailer.invite(invitation).deliver_now
      rescue => e
        Rails.logger.error "Failed to send account invitation email: #{e.class}"
      end
  end
end
