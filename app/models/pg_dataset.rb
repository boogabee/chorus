class PgDataset < RelationalDataset
  delegate :database, :to => :schema

  def data_source_account_ids
    database.data_source_account_ids
  end

  def database_name
    database.name
  end

  def execution_location
    database
  end

  def column_type
    'PgDatasetColumn'
  end
end
