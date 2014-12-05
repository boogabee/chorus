class AddConnectionParametersToHdfsDataSources < ActiveRecord::Migration
  def change
    add_column :hdfs_data_sources, :connection_parameters, :text
  end
end
