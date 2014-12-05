class RenameMaintenanceDbToDbName < ActiveRecord::Migration
  def change
    rename_column :data_sources, :maintenance_db, :db_name
  end
end
