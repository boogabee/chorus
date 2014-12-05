class AddDeletedAtToInstancesDatabasesAndSchemas < ActiveRecord::Migration
  def change
    add_column :gpdb_instances, :deleted_at, :timestamp
    add_column :gpdb_databases, :deleted_at, :timestamp
    add_column :gpdb_schemas, :deleted_at, :timestamp
  end
end
