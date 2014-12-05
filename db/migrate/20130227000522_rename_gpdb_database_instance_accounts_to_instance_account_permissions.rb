class RenameGpdbDatabaseInstanceAccountsToInstanceAccountPermissions < ActiveRecord::Migration
  def up
    rename_index :gpdb_databases_instance_accounts, 'gpdb_databases_instance_accounts_pkey', 'instance_account_permissions_pkey'
    rename_index :gpdb_databases_instance_accounts, 'index_gpdb_databases_instance_accounts_on_instance_account_id', 'index_instance_account_permissions_on_instance_account_id'
    rename_table :gpdb_databases_instance_accounts, :instance_account_permissions
    rename_column :instance_account_permissions, :gpdb_database_id, :accessed_id
    add_column :instance_account_permissions, :accessed_type, :string, null: false, default: 'GpdbDatabase'
    change_column_default :instance_account_permissions, :accessed_type, nil
    add_index :instance_account_permissions, [:accessed_id, :accessed_type], name: 'index_instance_account_permissions_on_accessed'
  end

  def down
    remove_index :instance_account_permissions, name: 'index_instance_account_permissions_on_accessed'
    remove_column :instance_account_permissions, :accessed_type
    rename_column :instance_account_permissions, :accessed_id, :gpdb_database_id
    rename_table :instance_account_permissions, :gpdb_databases_instance_accounts
    rename_index :gpdb_databases_instance_accounts, 'index_instance_account_permissions_on_instance_account_id', 'index_gpdb_databases_instance_accounts_on_instance_account_id'
    rename_index :gpdb_databases_instance_accounts, 'instance_account_permissions_pkey', 'gpdb_databases_instance_accounts_pkey'
  end
end
