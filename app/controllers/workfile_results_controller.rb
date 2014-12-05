class WorkfileResultsController < ApplicationController
  def create
    workfile = Workfile.find(params[:workfile_id])
    authorize! :create_note_on, workfile
    event = workfile.create_result_event(params[:result_id])
    present event, :status => :created
  end
end