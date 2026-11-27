class PagesController < ApplicationController
  def home
    @app_name = "Jumpstart Pro Plus"
    @build_commit = ENV.fetch("RAILWAY_GIT_COMMIT_SHA", "dev").first(7)
    @db_status = database_reachable? ? "Connected" : "Disconnected"
  end

  private

  # Run a real query: connection.active? is false until a query opens the lazy connection.
  def database_reachable?
    ActiveRecord::Base.connection.select_value("SELECT 1").to_i == 1
  rescue ActiveRecord::ActiveRecordError
    false
  end
end
