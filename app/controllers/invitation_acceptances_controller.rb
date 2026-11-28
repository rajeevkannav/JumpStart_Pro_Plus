# Accepting an emailed invitation.
#
#   GET /invitations/:token
#
# Signed-out visitors are asked to sign in or sign up; the link is remembered
# so they come straight back here afterwards. Signed-in users whose email
# matches the invitation become members and are switched to the account.
# Unknown, revoked (deleted), expired or already used tokens all render the
# same "invalid" page with a 404.
class InvitationAcceptancesController < ApplicationController
  allow_unauthenticated_access only: :show
  rate_limit to: 30, within: 10.minutes, only: :show, by: -> { request.remote_ip }, with: -> {
    redirect_to root_path, alert: "Try again later."
  }

  def show
    @invitation = AccountInvitation.includes(:account).find_by(token: params[:token].to_s)
    return render(:invalid, status: :not_found) unless @invitation&.acceptable?

    if !authenticated?
      session[:return_to_after_authenticating] = request.url
      render :show
    elsif !@invitation.for?(Current.user)
      render :wrong_user, status: :forbidden
    elsif @invitation.accept!(Current.user)
      Current.session.update!(account: @invitation.account)
      Current.account = @invitation.account
      redirect_to current_account_path, notice: "Welcome to #{@invitation.account.name}. You're now working in this account."
    else
      render :invalid, status: :not_found
    end
  end
end
