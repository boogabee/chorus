class AddLegacyIdToHdfsEntries < ActiveRecord::Migration
  def change
    add_column :hdfs_entries, :legacy_id, :string
  end
end
