# Membership of a user in an account.
class AccountUser < ApplicationRecord
  ROLES = %w[ owner admin member ].freeze
  # Roles an owner can hand out from the members page. "owner" is never
  # assignable directly: that's Account#transfer_ownership_to!.
  ASSIGNABLE_ROLES = %w[ member admin ].freeze
  # Each role and the roles it implies (an owner can do whatever an admin can).
  IMPLIED_ROLES = {
    "owner" => %i[ owner admin member ],
    "admin" => %i[ admin member ],
    "member" => %i[ member ]
  }.freeze

  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }
  validate :personal_account_has_only_its_owner

  def owner?
    role == "owner"
  end

  def admin?
    role == "admin"
  end

  # Every role this membership holds, e.g. [:admin, :member] for an admin.
  def roles
    IMPLIED_ROLES.fetch(role, [])
  end

  private
    def personal_account_has_only_its_owner
      return unless account&.personal?
      return if user_id == account.owner_id

      errors.add(:base, "Personal accounts can't have other members")
    end
end
