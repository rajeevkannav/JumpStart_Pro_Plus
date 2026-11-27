class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, allow_nil: true

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email_address
  end

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt
  end

  private

  def password_salt
    password_digest.split("$").last
  end
end
