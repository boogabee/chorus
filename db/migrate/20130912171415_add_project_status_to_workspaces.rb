class AddProjectStatusToWorkspaces < ActiveRecord::Migration
  def change
    add_column :workspaces, :project_status, :string, default: :on_track
    add_column :workspaces, :project_status_reason, :string
  end
end
