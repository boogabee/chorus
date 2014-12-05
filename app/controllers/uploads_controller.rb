class UploadsController < ApplicationController

  def create
    upload = Upload.new(contents: params[:contents])
    upload.user = current_user
    upload.save!

    present upload, :status => :created
  end
end
