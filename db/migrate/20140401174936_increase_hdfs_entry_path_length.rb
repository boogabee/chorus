class IncreaseHdfsEntryPathLength < ActiveRecord::Migration
  def up
    change_column :hdfs_entries, :path, :string, :limit => 4096
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'path details would be lost'
  end
end
