class RenameGpdbInstancesToDataSources < ActiveRecord::Migration
  def up
    add_column :gpdb_instances, :type, :string
    rename_table :gpdb_instances, :data_sources
    update "UPDATE data_sources SET type = 'GpdbInstance'"

    rename_index :data_sources, 'index_gpdb_instances_on_owner_id', 'index_data_sources_on_owner_id'

    execute("alter index gpdb_instances_pkey rename to data_sources_pkey;")
  end

  def down
    rename_table :data_sources, :gpdb_instances
    remove_column :gpdb_instances, :type

    rename_index :gpdb_instances, 'index_data_sources_on_owner_id', 'index_gpdb_instances_on_owner_id'

    execute("alter index data_sources_pkey rename to gpdb_instances_pkey;")
  end
end
