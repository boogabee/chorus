class ChangeWorkfileExecutionSchemaToExecutionLocation < ActiveRecord::Migration
  def up
    add_column :workfiles, :execution_location_type, :text
    execute "UPDATE workfiles SET execution_location_type='GpdbSchema' WHERE execution_schema_id IS NOT NULL"
    execute "UPDATE workfiles SET execution_location_type='GpdbDatabase' WHERE type = 'AlpineWorkfile'"
    rename_column :workfiles, :execution_schema_id, :execution_location_id
  end

  def down
    remove_column :workfiles, :execution_location_type
    rename_column :workfiles, :execution_location_id, :execution_schema_id
  end
end
