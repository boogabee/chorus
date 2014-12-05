class ImportabilitiesController < ApplicationController
  def show
    dataset = Dataset.find(params[:dataset_id])
    dataset_importability = DatasetImportability.new(dataset)
    present dataset_importability
  end
end
