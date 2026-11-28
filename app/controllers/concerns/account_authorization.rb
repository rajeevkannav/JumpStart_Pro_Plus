# Role checks for Current.account, in controllers and views.
#
#   class Accounts::InvitationsController < ApplicationController
#     include AccountScoped
#     require_account_role :admin                 # admins and the owner
#   end
#
#   class Accounts::RolesController < ApplicationController
#     include AccountScoped
#     require_account_role :owner                 # the owner only
#   end
#
# Anyone without the role gets a 404 (never 403), so nothing reveals that the
# page or record exists. Views use account_owner? / account_admin?.
module AccountAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :account_owner?, :account_admin?, :account_role?
  end

  class_methods do
    def require_account_role(role, **options)
      role = role.to_sym
      raise ArgumentError, "unknown role: #{role}" unless AccountUser::ROLES.include?(role.to_s)

      before_action(**options) { enforce_account_role(role) }
    end
  end

  private
    def account_role?(role)
      Current.roles.include?(role.to_sym)
    end

    def account_owner?
      account_role?(:owner)
    end

    # Admins and the owner.
    def account_admin?
      account_role?(:admin)
    end

    def enforce_account_role(role)
      raise ActiveRecord::RecordNotFound unless account_role?(role)
    end
end
