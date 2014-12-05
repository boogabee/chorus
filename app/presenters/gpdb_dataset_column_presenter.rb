class GpdbDatasetColumnPresenter < DatasetColumnPresenter
  def type_category
    GpdbDataTypes.pretty_category_name(model.data_type)
  end
end