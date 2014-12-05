class MembersController < ApplicationController
  def index
    workspace = Workspace.find(params[:workspace_id])
    authorize! :show, workspace

    present paginate WorkspaceAccess.members_for(current_user, workspace)
  end

  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :owner, workspace

    WorkspaceMembersManager.new(
        workspace,
        params[:member_ids],
        current_user
    ).update_membership

    present workspace.reload.members
  end
end
