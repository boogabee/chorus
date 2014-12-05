class RenameGpdbDatabasesToDatabases < ActiveRecord::Migration
  def up
    rename_table :gpdb_databases, :databases
    add_column :databases, :type, :string, :null => false, :default => 'GpdbDatabase'
    change_column_default :databases, :type, nil
  end

  def down
    remove_column :databases, :type
    rename_table :databases, :gpdb_databases
  end
end
