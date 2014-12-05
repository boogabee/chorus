class UpdateImportType < ActiveRecord::Migration
  def up
    execute("UPDATE imports SET type='WorkspaceImport' WHERE type IS NULL")
    change_column_null :imports, :type, false
  end

  def down
  end
end
