class AddDestinationDatasetIdToImportSchedules < ActiveRecord::Migration
  def change
    add_column :import_schedules, :destination_dataset_id, :integer
  end
end
