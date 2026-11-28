# A tenant. Every user has exactly one personal account (created with the
# user, see User#create_personal_account) and may belong to other accounts
# through AccountUser memberships. Tenant-owned data must be reached through
# Current.account.<association>, never with an unscoped Model.find.
class Account < ApplicationRecord
  TEAM_ACCOUNT_LIMIT = 10

  belongs_to :owner, class_name: "User"
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :sessions, dependent: :nullify
  has_many :invitations, class_name: "AccountInvitation", dependent: :delete_all

  validates :name, presence: true, length: { maximum: 100 }
  validates :owner_id, uniqueness: { conditions: -> { where(personal: true) } }, if: :personal?
  validate :within_team_account_limit, on: :create, unless: :personal?

  before_destroy :prevent_personal_account_deletion

  def owner?(user)
    user.present? && owner_id == user.id
  end

  def role_for(user)
    account_users.find_by(user: user)&.role
  end

  private
    def within_team_account_limit
      return unless owner
      return if owner.owned_accounts.where(personal: false).count < TEAM_ACCOUNT_LIMIT

      errors.add(:base, "You can own at most #{TEAM_ACCOUNT_LIMIT} team accounts. Delete one before creating another.")
    end

    def prevent_personal_account_deletion
      return unless personal?

      errors.add(:base, "Personal accounts can't be deleted")
      throw :abort
    end
end
