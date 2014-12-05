class AttachmentDownloadsController < ApplicationController

  def show
    attachment = Attachment.find(params[:attachment_id])
    authorize! :show, attachment.note

    download_file(attachment)
  end

  private

  def download_file(attachment)
    send_file attachment.contents.path, :disposition => 'attachment'
    ActiveRecord::Base.connection.close
  end
end
