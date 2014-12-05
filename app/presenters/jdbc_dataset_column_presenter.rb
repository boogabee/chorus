class JdbcDatasetColumnPresenter < DatasetColumnPresenter;
  def type_category
    JdbcDataTypes.pretty_category_name model.data_type
  end
end