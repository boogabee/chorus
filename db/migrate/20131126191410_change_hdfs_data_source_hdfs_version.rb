class ChangeHdfsDataSourceHdfsVersion < ActiveRecord::Migration

  class HdfsDataSource < ActiveRecord::Base; end

  def up
    HdfsDataSource.
        where(:hdfs_version => 'Pivotal HD').
        update_all(:hdfs_version => 'Pivotal HD 1.0')
  end

  def down
    HdfsDataSource.
        where(:hdfs_version => 'Pivotal HD 1.0').
        update_all(:hdfs_version => 'Pivotal HD')
  end
end
