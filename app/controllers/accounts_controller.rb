# Accounts the signed-in user belongs to. Every lookup goes through
# Current.user.accounts (members) or Current.user.owned_accounts (owners), so
# another tenant's account id raises RecordNotFound and renders 404, never 403.
# GET /account (no id) shows Current.account.
class AccountsController < ApplicationController
  require_account only: :show
  before_action :set_account, only: :show
  before_action :set_owned_account, only: %i[ edit update destroy ]
  require_sudo only: :destroy
  rate_limit to: 10, within: 1.hour, only: :create, with: -> {
    redirect_to accounts_path, alert: "Try again later."
  }

  def index
    @accounts = Current.user.accounts.order(personal: :desc, name: :asc)
  end

  def show
    @members = @account.account_users.includes(:user).order(:created_at)
    @role = @members.find { |membership| membership.user_id == Current.user.id }&.role
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params.merge(owner: Current.user, personal: false))

    saved = Account.transaction do
      @account.save &&
        @account.account_users.create!(user: Current.user, role: "owner") &&
        Current.session.update!(account: @account)
    end

    if saved
      Current.account = @account
      redirect_to @account, notice: "Team account created. You're now working in #{@account.name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: "Account updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @account.destroy
      redirect_to accounts_path, notice: "Account deleted."
    else
      redirect_to @account, alert: @account.errors.full_messages.to_sentence
    end
  end

  private
    def set_account
      @account = params[:id] ? Current.user.accounts.find(params[:id]) : Current.account
    end

    def set_owned_account
      @account = Current.user.owned_accounts.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name)
    end

    def sudo_return_to
      @account ? account_path(@account) : accounts_path
    end
end
