class Current < ActiveSupport::CurrentAttributes
  attribute :session, :account, :account_user
  delegate :user, to: :session, allow_nil: true

  # Setting the account also resolves the signed-in user's membership in it,
  # always through the account's own memberships (never another tenant's).
  def account=(account)
    super
    self.account_user = account && user && account.account_users.find_by(user_id: user.id)
  end

  # The roles the user holds in Current.account: owner implies admin, admin
  # implies member. Ownership follows accounts.owner_id.
  def roles
    return [] unless account && account_user

    account.owner?(user) ? AccountUser::IMPLIED_ROLES.fetch("owner") : account_user.roles
  end
end
