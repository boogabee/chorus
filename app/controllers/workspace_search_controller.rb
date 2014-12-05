class WorkspaceSearchController < ApplicationController
  before_filter :require_full_search

  def show
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace
    present WorkspaceSearch.new(current_user, params)
  end
end
