class RenameGpdbDatabaseGpdbDataSourceIdToDataSourceId < ActiveRecord::Migration
  def change
    rename_column :gpdb_databases, :gpdb_data_source_id, :data_source_id
  end
end
