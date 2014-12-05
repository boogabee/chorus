class JdbcDataset < RelationalDataset
  delegate :data_source, :to => :schema

  def column_type
    'JdbcDatasetColumn'
  end

  def all_rows_sql(limit = nil)
    Arel::Table.new(%("#{schema_name}"."#{name}")).project('*').to_sql
  end
end
