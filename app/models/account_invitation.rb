# An invitation for an email address to join a team account as a member.
# The token is the secret in the emailed link; it is never logged.
#
# Pending = not accepted and not expired. Revoking deletes the row, so a
# revoked token simply no longer resolves.
class AccountInvitation < ApplicationRecord
  EXPIRES_IN = 7.days

  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  has_secure_token

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :unaccepted, -> { where(accepted_at: nil) }
  scope :pending, -> { unaccepted.where(expires_at: Time.current..) }

  validates :email_address, presence: true, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email_address, uniqueness: { scope: :account_id, conditions: -> { unaccepted }, message: "has already been invited" }
  validate :account_is_a_team_account
  validate :invitee_is_not_already_a_member, on: :create

  before_validation :set_expiry, on: :create
  # An expired, never-accepted invitation must not block inviting the same
  # address again (the pending-uniqueness index ignores expiry).
  before_validation :remove_expired_invitation_for_same_email, on: :create

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def acceptable?
    !accepted? && !expired?
  end

  def for?(user)
    user.present? && user.email_address == email_address
  end

  # Adds the user as a member (keeping an existing role) and marks the
  # invitation used. Returns false if it can no longer be accepted.
  def accept!(user)
    transaction do
      lock!
      next false unless acceptable?

      account.account_users.find_or_create_by!(user: user) { |membership| membership.role = "member" }
      update!(accepted_at: Time.current)
    end
  end

  private
    def set_expiry
      self.expires_at ||= EXPIRES_IN.from_now
    end

    def remove_expired_invitation_for_same_email
      return if account.nil? || email_address.blank?

      account.invitations.unaccepted.where(email_address: email_address, expires_at: ..Time.current).delete_all
    end

    def account_is_a_team_account
      errors.add(:base, "Personal accounts can't invite members") if account&.personal?
    end

    def invitee_is_not_already_a_member
      return if account.nil? || email_address.blank?

      errors.add(:email_address, "already belongs to a member of this account") if account.users.exists?(email_address: email_address)
    end
end
