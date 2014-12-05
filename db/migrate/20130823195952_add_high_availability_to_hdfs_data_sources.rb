class AddHighAvailabilityToHdfsDataSources < ActiveRecord::Migration
  def up
    add_column :hdfs_data_sources, :high_availability, :boolean, :default => false
    change_column :hdfs_data_sources, :port, :integer, :null => true
    execute("UPDATE hdfs_data_sources SET high_availability = false")
  end

  def down
    remove_column :hdfs_data_sources, :high_availability
    change_column :hdfs_data_sources, :port, :integer, :null => false
  end
end
