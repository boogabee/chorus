class AddShowSandboxDatasetsToWorkspaces < ActiveRecord::Migration
  def up
    add_column :workspaces, :show_sandbox_datasets, :boolean, :default => true
    execute "update workspaces set show_sandbox_datasets = true"
  end

  def down
    remove_column :workspaces, :show_sandbox_datasets
  end
end
