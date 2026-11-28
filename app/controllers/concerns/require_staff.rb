# Global staff checks (users.staff = true). Staff is granted only by an
# operator with `bin/rails "staff:grant[email]"`; no param or form sets it.
#
#   class Staff::DashboardController < ApplicationController
#     require_staff
#   end
#
# Anyone else, signed in or not, gets a 404 so the page's existence isn't
# revealed (signed-out visitors aren't redirected to sign in either). Views
# use staff? (e.g. for the navbar link).
module RequireStaff
  extend ActiveSupport::Concern

  included do
    helper_method :staff?
  end

  class_methods do
    def require_staff(**options)
      allow_unauthenticated_access(**options)
      before_action :enforce_staff, **options
    end
  end

  private
    def staff?
      user = resume_session&.user
      user.present? && user.staff? && !user.deleted?
    end

    def enforce_staff
      raise ActiveRecord::RecordNotFound unless staff?
    end
end
