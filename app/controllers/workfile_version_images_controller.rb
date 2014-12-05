class WorkfileVersionImagesController < ApplicationController

  def show
    workfile_version = WorkfileVersion.find(params[:workfile_version_id])
    authorize! :show, workfile_version.workfile.workspace

    style = params[:style] ? params[:style] : 'original'
    content_type = workfile_version.contents_content_type
    file_path = workfile_version.contents.path(style)
    send_file file_path, :type => content_type
    ActiveRecord::Base.connection.close
  end
end