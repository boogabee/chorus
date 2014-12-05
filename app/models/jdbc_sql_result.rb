class JdbcSqlResult < SqlResult
  private

  def dataset_column_class
    JdbcDatasetColumn
  end
end