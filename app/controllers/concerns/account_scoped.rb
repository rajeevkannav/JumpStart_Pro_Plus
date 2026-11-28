# Include in controllers that serve tenant-owned data.
#
# Pattern: load every record through a Current.account association so a
# foreign id raises ActiveRecord::RecordNotFound (404, never 403):
#
#   class ProjectsController < ApplicationController
#     include AccountScoped
#
#     def index = @projects = Current.account.projects
#     def show  = @project  = Current.account.projects.find(params[:id])
#     def create = @project = Current.account.projects.create(project_params)
#   end
#
# Never Project.find(params[:id]) or Project.where(...) without the account,
# and never permit :account_id in strong parameters.
module AccountScoped
  extend ActiveSupport::Concern

  included do
    require_account
  end
end
