class AddIdAndDeletedAtIndexToWorkspaces < ActiveRecord::Migration
  def change
    add_index :workspaces, [:id, :deleted_at]
    add_index :workspaces, :deleted_at
  end
end
