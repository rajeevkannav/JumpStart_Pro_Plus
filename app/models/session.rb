class Session < ApplicationRecord
  SUDO_DURATION = 15.minutes

  belongs_to :user
  # The account selected in this session (nil = the user's personal account).
  belongs_to :account, optional: true

  validate :account_is_one_of_the_users

  # A fresh sign-in counts as sudo.
  before_create { self.sudo_at ||= Time.current }

  def sudo?
    sudo_at.present? && sudo_at > SUDO_DURATION.ago
  end

  def sudo!
    update!(sudo_at: Time.current)
  end

  # The account this session works in. The stored id is only ever resolved
  # through the user's own memberships, so a stale or foreign id (membership
  # removed, tampered row) falls back to the personal account.
  def current_account
    (account_id && user.accounts.find_by(id: account_id)) || user.personal_account
  end

  private
    def account_is_one_of_the_users
      return if account_id.nil? || !will_save_change_to_account_id?
      return if user&.accounts&.exists?(id: account_id)

      errors.add(:account, "must be an account you belong to")
    end
end
