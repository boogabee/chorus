class DefaultWorkspaceShowSandboxDatasetsToTrue < ActiveRecord::Migration
  def up
    execute "UPDATE workspaces SET show_sandbox_datasets = true WHERE show_sandbox_datasets IS NULL"
    execute "ALTER TABLE workspaces ALTER COLUMN show_sandbox_datasets SET DEFAULT true"
  end

  def down
    execute "ALTER TABLE workspaces ALTER COLUMN show_sandbox_datasets SET DEFAULT NULL"
  end
end
