class AddUniqueConstraintToGpdbDatabaseNames < ActiveRecord::Migration
  def change
    add_index :gpdb_databases, [:gpdb_instance_id, :name], :unique => true
  end
end
