class RenameGpdbInstanceToGpdbDataSource < ActiveRecord::Migration
  def up
    execute "UPDATE data_sources SET type = 'GpdbDataSource' WHERE type = 'GpdbInstance'"
    execute "UPDATE events SET target1_type = 'DataSource' WHERE target1_type = 'GpdbInstance'"
    execute "UPDATE events SET target2_type = 'DataSource' WHERE target2_type = 'GpdbInstance'"
    rename_column :gpdb_databases, :gpdb_instance_id, :gpdb_data_source_id
  end

  def down
    execute "UPDATE data_sources SET type = 'GpdbInstance' WHERE type = 'GpdbDataSource'"
    execute "UPDATE events SET target1_type = 'GpdbInstance' WHERE target1_type = 'DataSource'"
    execute "UPDATE events SET target2_type = 'GpdbInstance' WHERE target2_type = 'DataSource'"
    rename_column :gpdb_databases, :gpdb_data_source_id, :gpdb_instance_id
  end
end
