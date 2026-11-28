class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(deleted_at: nil) }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email_address
  end

  def email_confirmed?
    email_confirmed_at.present?
  end

  def deleted?
    deleted_at.present?
  end

  # Soft delete: keeps the row so it can be purged later, signs the user
  # out everywhere and frees the email address so it can sign up again.
  def soft_delete!
    transaction do
      sessions.destroy_all
      update!(deleted_at: Time.current, email_address: "deleted-#{id}@invalid")
    end
  end
end
