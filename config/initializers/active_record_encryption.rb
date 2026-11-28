# Active Record encryption keys (used by User#otp_secret).
#
# Set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY, ..._DETERMINISTIC_KEY and
# ..._KEY_DERIVATION_SALT in the environment to manage keys explicitly.
# Otherwise each key is derived from secret_key_base, so no credentials
# edits are needed. Changing secret_key_base (or the env keys) makes
# existing encrypted values unreadable.
Rails.application.configure do
  {
    primary_key: "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY",
    deterministic_key: "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY",
    key_derivation_salt: "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"
  }.each do |name, env_var|
    config.active_record.encryption[name] = ENV[env_var].presence ||
      key_generator.generate_key("active_record_encryption.#{name}", 32).unpack1("H*")
  end
end
