class AddHdfsVersionToHdfsDataSources < ActiveRecord::Migration
  def change
    add_column :hdfs_data_sources, :hdfs_version, :string
  end
end
