class DropUnnecessaryColumnsFromImports < ActiveRecord::Migration
  def up
    remove_column :import_schedules, :last_scheduled_at
    remove_column :import_schedules, :dataset_import_created_event_id
  end

  def down
    add_column :import_schedules, :dataset_import_created_event_id, :integer
    add_column :import_schedules, :last_scheduled_at, :timestamp
  end
end