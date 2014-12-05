class AddIsProjectToWorkspaces < ActiveRecord::Migration
  def change
    add_column :workspaces, :is_project, :boolean, default: true
  end
end
