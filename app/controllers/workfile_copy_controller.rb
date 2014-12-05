class WorkfileCopyController < ApplicationController

  def create
    workfile = Workfile.find(params[:workfile_id])
    authorize! :show, workfile

    workspace = params[:workspace_id].nil? ? workfile.workspace : Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace

    copied_workfile = workfile.copy!(current_user, workspace, params[:file_name])

    present copied_workfile.reload, :status => :created
  end
end
