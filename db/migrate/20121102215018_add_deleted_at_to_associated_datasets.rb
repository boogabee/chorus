class AddDeletedAtToAssociatedDatasets < ActiveRecord::Migration
  def change
    add_column :associated_datasets, :deleted_at, :timestamp
  end
end
