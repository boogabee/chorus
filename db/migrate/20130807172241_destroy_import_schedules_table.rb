class DestroyImportSchedulesTable < ActiveRecord::Migration
  def up
    drop_table :import_schedules
  end

  def down
    create_table :import_schedules do |t|
      t.datetime :start_datetime
      t.date :end_date
      t.string :frequency
      t.datetime :next_import_at
      t.datetime :deleted_at
      t.timestamps

      t.integer :workspace_id
      t.string :to_table
      t.integer :source_dataset_id
      t.boolean :truncate
      t.boolean :new_table
      t.integer :user_id
      t.integer :sample_count
      t.string :legacy_id
      t.integer :destination_dataset_id
    end
  end
end
