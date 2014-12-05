class AddRefreshedAtToGpdbSchema < ActiveRecord::Migration
  def change
    add_column :gpdb_schemas, :refreshed_at, :timestamp
  end
end
