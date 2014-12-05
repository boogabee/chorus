class MilestonesController < ApplicationController
  before_filter :require_milestones

  def index
    authorize! :show, workspace

    milestones = workspace.milestones.order(:target_date)

    present paginate(milestones), :presenter_options => {:list_view => true}
  end

  def create
    authorize! :can_edit_sub_objects, workspace

    milestone = workspace.milestones.create params[:milestone]

    present milestone, :status => :created
  end

  def destroy
    authorize! :can_edit_sub_objects, workspace

    Milestone.find(params[:id]).destroy

    head :ok
  end

  def update
    authorize! :can_edit_sub_objects, workspace

    milestone = workspace.milestones.find(params[:id])
    milestone.update_attributes!(params[:milestone])

    head :ok
  end

  protected

  def workspace
    @workspace ||= Workspace.find(params[:workspace_id])
  end

  def require_milestones
    render_not_licensed if License.instance.limit_milestones?
  end
end
