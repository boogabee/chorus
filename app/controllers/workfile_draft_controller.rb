class WorkfileDraftController < ApplicationController
  def create
    workfile = Workfile.find(params[:workfile_id])
    authorize! :can_edit_sub_objects, workfile.workspace

    draft = WorkfileDraft.new(params[:workfile_draft])
    draft.workfile_id = params[:workfile_id]
    draft.owner_id = current_user.id
    draft.save!
    present draft, :status => :created
  end

  def show
    workfile = Workfile.find(params[:workfile_id])
    authorize! :show, workfile.workspace

    draft = WorkfileDraft.find_by_owner_id_and_workfile_id!(current_user.id, params[:workfile_id])
    present draft
  end

  def update
    workfile = Workfile.find(params[:workfile_id])
    authorize! :can_edit_sub_objects, workfile.workspace

    draft = WorkfileDraft.find_by_owner_id_and_workfile_id!(current_user.id, params[:workfile_id])
    draft.update_attributes!(params[:workfile_draft])
    present draft
  end

  def destroy
    workfile = Workfile.find(params[:workfile_id])
    authorize! :can_edit_sub_objects, workfile.workspace

    draft = WorkfileDraft.find_by_owner_id_and_workfile_id!(current_user.id, params[:workfile_id])
    draft.destroy
    render :json => {}
  end
end