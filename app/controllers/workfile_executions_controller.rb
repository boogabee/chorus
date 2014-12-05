class WorkfileExecutionsController < ApplicationController
  include FileDownloadHelper
  before_filter :find_workfile, :find_schema, :verify_workspace, :check_authorization
  require_params :check_id, :only => :create
  require_params :id, :only => :destroy, :field_name => :check_id

  def create
    query = CancelableQuery.new(@schema.connect_as(current_user), params[:check_id], current_user)
    if params[:download]
      cookies["fileDownload_#{params[:check_id]}".to_sym] = true
      filename = filename_for_download("#{params[:file_name]}.csv")
      response.headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
      response.headers["Cache-Control"] = 'no-cache'
      response.headers["Transfer-Encoding"] = 'chunked'
      response.headers['Content-Type'] = 'text/csv'

      self.response_body = query.stream(params[:sql], :row_limit => params[:num_of_rows].to_i)
    else
      present query.execute(params[:sql], :limit => ChorusConfig.instance['default_preview_row_limit'],
                                      :include_public_schema_in_search_path => true)
    end
  end

  def destroy
    CancelableQuery.cancel(params[:id], current_user)
    head :ok
  end

  private

  def find_workfile
    @workfile = Workfile.find(params[:workfile_id] || params[:id])
  end

  def find_schema
    @schema = @workfile.execution_schema
  end

  def verify_workspace
    present_errors({:fields => {:workspace => {:ARCHIVED => {}}}}, :status => :unprocessable_entity) if @workfile.workspace.archived?
  end

  def check_authorization
    authorize! :can_edit_sub_objects, @workfile.workspace
  end
end