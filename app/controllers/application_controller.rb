class ApplicationController < ActionController::Base
  include Authentication
  include RequireSudo
  allow_browser versions: :modern
end
