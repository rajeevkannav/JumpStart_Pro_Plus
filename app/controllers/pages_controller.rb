class PagesController < ApplicationController
  def home
    @app_name = "Jumpstart Pro Plus"
    @render_commit = ENV.fetch("RENDER_GIT_COMMIT", "dev")
    @db_status = ActiveRecord::Base.connection.active? ? "Connected" : "Disconnected"
  end
end
