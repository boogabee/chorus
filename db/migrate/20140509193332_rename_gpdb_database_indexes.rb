class RenameGpdbDatabaseIndexes < ActiveRecord::Migration
  def change
    rename_index :datasets, 'index_gpdb_database_objects_on_schema_id', 'index_database_objects_on_schema_id'
    rename_index :data_source_account_permissions, 'index_gpdb_databases_instance_accounts_on_gpdb_database_id', 'index_databases_instance_accounts_on_database_id'
    rename_index :databases, 'index_gpdb_databases_on_gpdb_instance_id_and_name', 'index_databases_on_data_source_id_and_name'
    rename_index :databases, 'index_gpdb_databases_on_instance_id', 'index_databases_on_data_source_id'
  end
end
