class ChangeHdfsEntrySizeFromIntToBigInt < ActiveRecord::Migration
  def change
    change_column :hdfs_entries, :size, :bigint
  end
end
