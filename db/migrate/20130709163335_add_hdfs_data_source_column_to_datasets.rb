class AddHdfsDataSourceColumnToDatasets < ActiveRecord::Migration
  def change
    add_column :datasets, :hdfs_data_source_id, :integer
  end
end
