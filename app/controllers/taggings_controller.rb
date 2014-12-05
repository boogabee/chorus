class TaggingsController < ApplicationController
  MAXIMUM_TAG_LENGTH=100
  wrap_parameters :tagging, :exclude => []

  def create
    taggables = params[:tagging][:taggables]
    taggables.each do |taggable|
      model = ModelMap.model_from_params(taggable[:entity_type], taggable[:entity_id])
      authorize! :show, model

      tag_names = model.tags.map(&:name)

      if params[:tagging][:add]
        tag_name = params[:tagging][:add]
        raise_validation_error if tag_name.length > MAXIMUM_TAG_LENGTH
        tag_names << tag_name
        tag_names.uniq!(&:downcase)
      else
        tag_name = params[:tagging][:remove]
        tag_names.reject! { |item| item.downcase == tag_name.downcase }
      end

      model.tag_list = tag_names.sort
      model.save!
    end

    render :json => {}, :status => :created
  end

  def index
    model = ModelMap.model_from_params(params[:entity_type], params[:entity_id])
    authorize! :show, model
    present model.tags
  end

  private

  def raise_validation_error
    raise ApiValidationError.new(:base, :too_long,
                                 {:field => "Tag",
                                  :count => MAXIMUM_TAG_LENGTH })
  end
end
