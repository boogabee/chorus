class DataDownloadsController < ApplicationController
  include FileDownloadHelper

  def download_data
    send_data params[:content], :type => params[:mime_type], :filename => filename_for_download(params[:filename])
  end
end
