class AddUniqueIndexToWorkfileName < ActiveRecord::Migration
  def up
    execute "CREATE UNIQUE INDEX index_workfiles_on_file_name_and_workspace_id ON workfiles (file_name, workspace_id) WHERE deleted_at IS NULL"
  end

  def down
    execute "DROP INDEX index_workfiles_on_file_name_and_workspace_id"
  end
end
