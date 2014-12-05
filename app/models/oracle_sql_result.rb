class OracleSqlResult < SqlResult
  private

  def dataset_column_class
    OracleDatasetColumn
  end
end
