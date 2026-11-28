class ApplicationController < ActionController::Base
  include Authentication
  include SetCurrentAccount
  include AccountAuthorization
  include RequireSudo
  include RequireStaff
  allow_browser versions: :modern
end
