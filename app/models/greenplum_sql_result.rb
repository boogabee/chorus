class GreenplumSqlResult < SqlResult
  private

  def dataset_column_class
    GpdbDatasetColumn
  end
end
