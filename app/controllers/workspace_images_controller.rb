class WorkspaceImagesController < ImagesController

  protected

  def load_entity
    @entity = Workspace.find(params[:workspace_id])
  end

  def authorize_create!
    authorize! :owner, @entity
  end

  def authorize_show!
    authorize! :show, @entity
  end
end
