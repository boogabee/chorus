class AddDefaultExecutionSchemaToWorkfiles < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE workfiles SET execution_schema_id = (SELECT sandbox_id from workspaces where workspaces.id = workfiles.workspace_id)
      WHERE workfiles.type = 'ChorusWorkfile' AND content_type = 'sql' AND execution_schema_id IS NULL AND deleted_at IS NULL
    SQL
  end

  def down
  end
end
