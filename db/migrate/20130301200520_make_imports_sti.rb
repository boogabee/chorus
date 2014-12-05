class MakeImportsSti < ActiveRecord::Migration
  def change
    add_column :imports, :type, :string, default: 'WorkspaceImport'
    add_column :imports, :schema_id, :integer
    change_column_default :imports, :type, nil
  end
end
