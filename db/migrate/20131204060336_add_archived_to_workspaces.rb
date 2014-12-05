class AddArchivedToWorkspaces < ActiveRecord::Migration
  def up
    add_column :workspaces, :archived, :boolean, :default => false
    execute('UPDATE workspaces SET archived = true WHERE archived_at IS NOT NULL')
    execute('UPDATE workspaces SET archived = false WHERE archived_at IS NULL')
  end

  def down
    remove_column :workspaces, :archived
  end
end
