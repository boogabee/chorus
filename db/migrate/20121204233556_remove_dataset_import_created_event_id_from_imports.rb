class RemoveDatasetImportCreatedEventIdFromImports < ActiveRecord::Migration
  def up
    remove_column :imports, :dataset_import_created_event_id
  end

  def down
    add_column :imports, :dataset_import_created_event_id, :integer
  end
end
