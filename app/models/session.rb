class Session < ApplicationRecord
  SUDO_DURATION = 15.minutes

  belongs_to :user

  # A fresh sign-in counts as sudo.
  before_create { self.sudo_at ||= Time.current }

  def sudo?
    sudo_at.present? && sudo_at > SUDO_DURATION.ago
  end

  def sudo!
    update!(sudo_at: Time.current)
  end
end
