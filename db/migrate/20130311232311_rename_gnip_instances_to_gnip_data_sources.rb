class RenameGnipInstancesToGnipDataSources < ActiveRecord::Migration
  def up
    rename_table :gnip_instances, :gnip_data_sources
    execute 'ALTER INDEX gnip_instances_pkey RENAME to gnip_data_sources_pkey'
    rename_index :gnip_data_sources, 'index_gnip_instances_on_owner_id', 'index_gnip_data_sources_on_owner_id'
    execute "UPDATE events SET action='Events::NoteOnGnipDataSource' WHERE action='Events::NoteOnGnipInstance'"
    execute "UPDATE events SET action='Events::GnipDataSourceCreated' WHERE action='Events::GnipInstanceCreated'"
    execute "UPDATE events SET target1_type='GnipDataSource' WHERE target1_type='GnipInstance'"
    execute "UPDATE events SET target2_type='GnipDataSource' WHERE target2_type='GnipInstance'"
  end

  def down
    execute "UPDATE events SET target2_type='GnipInstance' WHERE target2_type='GnipDataSource'"
    execute "UPDATE events SET target1_type='GnipInstance' WHERE target1_type='GnipDataSource'"
    execute "UPDATE events SET action='Events::GnipInstanceCreated' WHERE action='Events::GnipDataSourceCreated'"
    execute "UPDATE events SET action='Events::NoteOnGnipInstance' WHERE action='Events::NoteOnGnipDataSource'"
    rename_index :gnip_data_sources, 'index_gnip_data_sources_on_owner_id', 'index_gnip_instances_on_owner_id'
    execute 'ALTER INDEX gnip_data_sources_pkey RENAME to gnip_instances_pkey'
    rename_table :gnip_data_sources, :gnip_instances
  end
end
