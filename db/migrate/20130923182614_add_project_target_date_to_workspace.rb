class AddProjectTargetDateToWorkspace < ActiveRecord::Migration
  def up
    add_column :workspaces, :project_target_date, :date
  end

  def down
    remove_column :workspaces, :project_target_date
  end
end
