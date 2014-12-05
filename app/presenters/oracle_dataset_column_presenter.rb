class OracleDatasetColumnPresenter < DatasetColumnPresenter
  def type_category
    OracleDataTypes.pretty_category_name(model.data_type)
  end
end