# A one-time code that stands in for a TOTP code when the user has lost
# their authenticator. Only a BCrypt digest is stored; the plain code is
# shown once, right after two-factor authentication is enabled.
class RecoveryCode < ApplicationRecord
  COUNT = 10
  LENGTH = 10

  belongs_to :user

  scope :unused, -> { where(used_at: nil) }

  # Replaces the user's codes with a fresh set and returns the plain codes
  # (formatted "abcde-12345") for display. They can't be recovered later.
  def self.regenerate_for(user)
    codes = Array.new(COUNT) { SecureRandom.alphanumeric(LENGTH).downcase }
    transaction do
      user.recovery_codes.delete_all
      codes.each { |code| user.recovery_codes.create!(code_digest: digest(code)) }
    end
    codes.map { |code| code.scan(/.{5}/).join("-") }
  end

  def self.digest(code)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(normalize(code), cost: cost)
  end

  # Accepts codes with or without the dash, any case, surrounding spaces.
  def self.normalize(code)
    code.to_s.downcase.gsub(/[^a-z0-9]/, "")
  end

  def matches?(code)
    BCrypt::Password.new(code_digest).is_password?(self.class.normalize(code))
  end

  # Marks the code used. The conditional UPDATE means two concurrent
  # requests can't both spend the same code.
  def consume!
    self.class.unused.where(id: id).update_all(used_at: Time.current, updated_at: Time.current) == 1
  end
end
