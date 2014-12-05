class AddDestinationDatasetIdToImports < ActiveRecord::Migration
  def change
    add_column :imports, :destination_dataset_id, :integer
  end
end
