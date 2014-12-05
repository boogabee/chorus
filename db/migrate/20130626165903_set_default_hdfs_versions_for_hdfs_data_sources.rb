class SetDefaultHdfsVersionsForHdfsDataSources < ActiveRecord::Migration
  class HdfsDataSource < ActiveRecord::Base
    HDFS_VERSIONS = {
      '2.0.0' => 'Pivotal HD',
      '0.20.2mr' => 'MapR',
      '1.0.0' => 'Greenplum HD 1.2',
      '0.20.1gp' => 'Greenplum HD 0.20'
    }
  end

  def up
    HdfsDataSource.find_each do |h|
      h.hdfs_version = HdfsDataSource::HDFS_VERSIONS[h.version] || 'Greenplum HD 1.2'
      h.save
    end
  end

  def down
    HdfsDataSource.update_all(:hdfs_version => nil)
  end
end
