Rails.application.configure do
  config.assume_ssl = true
  config.force_ssl = true
  config.log_level = :info
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.active_storage.service = :local
  config.force_ssl = true
end