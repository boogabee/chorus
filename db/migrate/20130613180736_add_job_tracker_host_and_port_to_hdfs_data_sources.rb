class AddJobTrackerHostAndPortToHdfsDataSources < ActiveRecord::Migration
  def change
    add_column :hdfs_data_sources, :job_tracker_host, :string
    add_column :hdfs_data_sources, :job_tracker_port, :integer
  end
end
