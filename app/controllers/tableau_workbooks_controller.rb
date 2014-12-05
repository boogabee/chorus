require 'optparse'

class TableauWorkbooksController < ApplicationController
  def create
    workspace = Workspace.find(params[:workspace_id])
    authorize! :can_edit_sub_objects, workspace
    dataset = Dataset.find(params[:dataset_id])
    publisher = TableauPublisher.new(current_user)
    publication = publisher.publish_workbook(dataset, workspace, params)
    render_publication publication
  end

  def render_publication(publication)
    render :json => {
        :response => {
            :name => publication.name,
            :dataset_id => publication.dataset_id,
            :id => publication.id,
            :url => publication.workbook_url,
            :project_url => publication.project_url
        }
    }, :status => :created
  end
end
