class MigrateSupportedHdfsVersions < ActiveRecord::Migration
  def up
    execute(%(UPDATE hdfs_data_sources SET hdfs_version = 'Apache Hadoop 1.2' WHERE hdfs_version IN ('Apache Hadoop 0.20.2', 'Apache Hadoop 0.20.203', 'Apache Hadoop 1.0.4')))
    execute(%(UPDATE hdfs_data_sources SET hdfs_version = 'Pivotal HD 1.1' WHERE hdfs_version IN ('Greenplum HD 0.20', 'Greenplum HD 1.1', 'Greenplum HD 1.2')))
  end

  def down
    execute(%(UPDATE hdfs_data_sources SET hdfs_version = 'Apache Hadoop 0.20.2' WHERE hdfs_version IN ('Apache Hadoop 1.2')))
  end
end
