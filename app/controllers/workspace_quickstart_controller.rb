class WorkspaceQuickstartController < ApplicationController
  def destroy
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    workspace.has_added_member = true
    workspace.has_added_sandbox = true
    workspace.has_added_workfile = true
    workspace.has_changed_settings = true
    workspace.save!

    present workspace
  end
end