class ApplicationController < ActionController::Base
  include Authentication
  include SetCurrentAccount
  include RequireSudo
  allow_browser versions: :modern
end
