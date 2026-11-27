module ApplicationHelper
  def build_sha
    ENV.fetch("RAILWAY_GIT_COMMIT_SHA", "dev")[0..7]
  end

  def database_status
    ActiveRecord::Base.connection.execute("SELECT 1")
    "Connected"
  rescue StandardError
    "Disconnected"
  end

  def app_environment
    Rails.env
  end
end
