class ImagesController < ApplicationController
  before_filter :load_entity

  def create
    authorize_create!
    @entity.image = params[:files][0]
    @entity.save!
    present @entity.image, :content_type => 'text/html'
  end

  def show
    authorize_show!
    raise ActiveRecord::RecordNotFound unless @entity.image && @entity.image_content_type
    style = params[:style] ? params[:style] : 'original'
    send_file @entity.image.path(style), :type => @entity.image_content_type
    ActiveRecord::Base.connection.close
  end

  protected
  def load_entity
    raise  NotImplementedError, "Method Not implemented"
  end

  def authorize_create!
    raise  NotImplementedError, "Method Not implemented"
  end

  def authorize_show!
    raise  NotImplementedError, "Method Not implemented"
  end
end
