class AddDeletedAtToHdfsDataSourcesAndEntries < ActiveRecord::Migration
  def change
    add_column :hdfs_data_sources, :deleted_at, :timestamp
    add_index :hdfs_data_sources, [:deleted_at, :id]

    add_column :hdfs_entries, :deleted_at, :timestamp
    add_index :hdfs_entries, [:deleted_at, :id]

    add_index :data_sources, [:deleted_at, :id]
    add_index :gpdb_databases, [:deleted_at, :id]
    add_index :schemas, [:deleted_at, :id]
  end
end
