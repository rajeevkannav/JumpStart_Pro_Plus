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

  # Removes a membership (an owner removing someone, or a member leaving).
  # The owner can't be removed: ownership must be transferred first. Any of
  # the removed user's sessions working in this account fall back to their
  # personal account.
  def remove_member!(membership)
    raise ArgumentError, "membership belongs to another account" unless membership.account_id == id
    raise MembershipError, "The owner can't leave or be removed. Transfer ownership first." if membership.user_id == owner_id

    transaction do
      membership.destroy!
      sessions.where(user_id: membership.user_id).update_all(account_id: nil, updated_at: Time.current)
    end
  end

  # Switches a membership between "member" and "admin". The owner's own role
  # can't change here and nobody becomes "owner" this way: that's
  # transfer_ownership_to!.
  def change_role!(membership, role)
    raise ArgumentError, "membership belongs to another account" unless membership.account_id == id
    raise MembershipError, "Choose member or admin." unless AccountUser::ASSIGNABLE_ROLES.include?(role.to_s)
    raise MembershipError, "The owner's role can't be changed. Transfer ownership instead." if membership.user_id == owner_id

    membership.update!(role: role.to_s)
  end

  # Makes another existing member the owner. owner_id and both roles change
  # in one transaction; the previous owner stays on as a member.
  def transfer_ownership_to!(new_owner)
    raise MembershipError, "Personal accounts can't be transferred." if personal?

    transaction do
      lock!
      raise MembershipError, "You already own this account." if new_owner.id == owner_id
      raise MembershipError, "That person can't own accounts." if new_owner.deleted?

      new_membership = account_users.lock.find_by(user_id: new_owner.id)
      raise MembershipError, "Only an existing member can become the owner." unless new_membership
      if new_owner.owned_accounts.where(personal: false).count >= TEAM_ACCOUNT_LIMIT
        raise MembershipError, "#{new_owner.email_address} already owns #{TEAM_ACCOUNT_LIMIT} team accounts."
      end

      account_users.where(user_id: owner_id).update_all(role: "member", updated_at: Time.current)
      new_membership.update!(role: "owner")
      update!(owner: new_owner)
    end
  end

  class MembershipError < StandardError; end

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
