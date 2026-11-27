class PagesController < ApplicationController
  def home
    @build_sha = ENV.fetch("RENDER_GIT_COMMIT", "dev")
  end
end