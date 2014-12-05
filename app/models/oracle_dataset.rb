class OracleDataset < RelationalDataset
  delegate :data_source, :to => :schema

  def column_type
    "OracleDatasetColumn"
  end

  def all_rows_sql(limit = nil)
    select_clause = column_data.map do |column_data|
      if column_data.supported?
        "\"#{column_data.name}\""
      else
        "'#{column_data.data_type.downcase}' AS \"#{column_data.name}\""
      end
    end.join(', ')
    query = "SELECT #{select_clause} FROM \"#{schema.name}\".\"#{name}\""
    query << " WHERE rownum <= #{limit}" if limit
    query
  end
end
