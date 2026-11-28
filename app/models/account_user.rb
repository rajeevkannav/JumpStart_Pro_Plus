# Membership of a user in an account.
class AccountUser < ApplicationRecord
  ROLES = %w[ owner member ].freeze

  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }
  validate :personal_account_has_only_its_owner

  def owner?
    role == "owner"
  end

  private
    def personal_account_has_only_its_owner
      return unless account&.personal?
      return if user_id == account.owner_id

      errors.add(:base, "Personal accounts can't have other members")
    end
end
