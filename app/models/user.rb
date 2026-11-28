class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users
  has_many :owned_accounts, class_name: "Account", foreign_key: :owner_id, inverse_of: :owner
  has_one :personal_account, -> { where(personal: true) }, class_name: "Account", foreign_key: :owner_id, inverse_of: :owner
  has_many :recovery_codes, dependent: :delete_all

  OTP_ISSUER = "JumpStart Pro Plus".freeze
  # Accept the previous and next 30-second step to allow for clock drift.
  OTP_DRIFT = 30

  encrypts :otp_secret

  # Runs inside the same transaction as the INSERT, so a user never exists
  # without their personal account.
  after_create :create_personal_account_with_membership

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(deleted_at: nil) }

  # Operator-only (see lib/tasks/staff.rake): grants or revokes the global
  # staff flag. Never reachable from params.
  def self.set_staff!(email, staff)
    raise ArgumentError, "Usage: bin/rails \"staff:#{staff ? 'grant' : 'revoke'}[email]\"" if email.blank?

    user = active.find_by(email_address: email.to_s.strip.downcase)
    raise ActiveRecord::RecordNotFound, "No user with email #{email}" unless user

    user.update!(staff: staff)
    user
  end

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

  def self.generate_otp_secret
    ROTP::Base32.random
  end

  def self.otp_code_valid?(secret, code)
    code = code.to_s.gsub(/\s/, "")
    return false if secret.blank? || !code.match?(/\A\d{6}\z/)

    ROTP::TOTP.new(secret, issuer: OTP_ISSUER).verify(code, drift_behind: OTP_DRIFT, drift_ahead: OTP_DRIFT).present?
  end

  def otp_provisioning_uri(secret)
    ROTP::TOTP.new(secret, issuer: OTP_ISSUER).provisioning_uri(email_address)
  end

  def two_factor_enabled?
    otp_enabled_at.present? && otp_secret.present?
  end

  # Turns two-factor on when +code+ is valid for +secret+ and returns the
  # new plain recovery codes, or nil (nothing changed) when it isn't.
  def enable_two_factor!(secret, code)
    return unless self.class.otp_code_valid?(secret, code)

    transaction do
      update!(otp_secret: secret, otp_enabled_at: Time.current)
      RecoveryCode.regenerate_for(self)
    end
  end

  def disable_two_factor!
    transaction do
      recovery_codes.delete_all
      update!(otp_secret: nil, otp_enabled_at: nil)
    end
  end

  # True for a current TOTP code, or for an unused recovery code (which is
  # then spent and won't work again).
  def verify_two_factor(code)
    return false unless two_factor_enabled?
    return true if self.class.otp_code_valid?(otp_secret, code)

    consume_recovery_code(code)
  end

  # Soft delete: keeps the row so it can be purged later, signs the user
  # out everywhere and frees the email address so it can sign up again.
  def soft_delete!
    transaction do
      sessions.destroy_all
      update!(deleted_at: Time.current, email_address: "deleted-#{id}@invalid")
      personal_account&.update!(name: email_address)
    end
  end

  private
    def consume_recovery_code(code)
      return false if RecoveryCode.normalize(code).length != RecoveryCode::LENGTH

      match = recovery_codes.unused.detect { |recovery_code| recovery_code.matches?(code) }
      match.present? && match.consume!
    end

    def create_personal_account_with_membership
      account = Account.create!(name: email_address, personal: true, owner: self)
      account.account_users.create!(user: self, role: "owner")
    end
end
