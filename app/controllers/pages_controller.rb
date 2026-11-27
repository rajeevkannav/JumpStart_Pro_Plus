class PagesController < ApplicationController
  def home
    @app_name = "Jumpstart Pro Plus"
    @build_commit = ENV.fetch("RAILWAY_GIT_COMMIT_SHA", "dev").first(7)
    @db_status = ActiveRecord::Base.connection.active? ? "Connected" : "Disconnected"
  end
end
