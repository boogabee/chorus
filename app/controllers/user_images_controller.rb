class UserImagesController < ImagesController
  protected

  def load_entity
    @entity = User.find(params[:user_id])
  end

  def authorize_create!
    authorize! :update, @entity
  end

  def authorize_show!
    true
  end
end
