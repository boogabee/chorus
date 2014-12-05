class RenameHadoopInstanceToHdfsDataSource < ActiveRecord::Migration
  def up
    rename_table :hadoop_instances, :hdfs_data_sources
    rename_column :hdfs_entries, :hadoop_instance_id, :hdfs_data_source_id
    execute "UPDATE events SET action='Events::NoteOnHdfsDataSource' WHERE action='Events::NoteOnHadoopInstance'"
    execute "UPDATE events SET target1_type='HdfsDataSource' WHERE target1_type='HadoopInstance'"
    execute "UPDATE events SET target2_type='HdfsDataSource' WHERE target2_type='HadoopInstance'"
    execute "UPDATE events SET action='Events::HdfsDataSourceCreated' WHERE action='Events::HadoopInstanceCreated'"
    execute "UPDATE events SET action='Events::HdfsDataSourceChangedName' WHERE action='Events::HadoopInstanceChangedName'"
    rename_index :hdfs_data_sources, 'index_hadoop_instances_on_owner_id', 'index_hdfs_data_sources_on_owner_id'
    execute 'ALTER INDEX hadoop_instances_pkey RENAME to hdfs_data_sources_pkey'
  end

  def down
    execute 'ALTER INDEX hdfs_data_sources_pkey RENAME to hadoop_instances_pkey'
    rename_index :hdfs_data_sources, 'index_hdfs_data_sources_on_owner_id', 'index_hadoop_instances_on_owner_id'
    execute "UPDATE events SET action='Events::NoteOnHadoopInstance' WHERE action='Events::NoteOnHdfsDataSource'"
    execute "UPDATE events SET target1_type='HadoopInstance' WHERE target1_type='HdfsDataSource'"
    execute "UPDATE events SET target2_type='HadoopInstance' WHERE target2_type='HdfsDataSource'"
    execute "UPDATE events SET action='Events::HadoopInstanceCreated' WHERE action='Events::HdfsDataSourceCreated'"
    execute "UPDATE events SET action='Events::HadoopInstanceChangedName' WHERE action='Events::HdfsDataSourceChangedName'"
    rename_column :hdfs_entries, :hdfs_data_source_id, :hadoop_instance_id
    rename_table :hdfs_data_sources, :hadoop_instances
  end
end
