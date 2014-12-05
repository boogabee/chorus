class AddDeletedAtToGnipDataSources < ActiveRecord::Migration
  def change
    add_column :gnip_data_sources, :deleted_at, :timestamp
    add_index :gnip_data_sources, [:deleted_at, :id]
  end
end
