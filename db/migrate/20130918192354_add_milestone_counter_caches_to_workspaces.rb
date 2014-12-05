class AddMilestoneCounterCachesToWorkspaces < ActiveRecord::Migration
  def up
    add_column :workspaces, :milestones_count, :integer, default: 0
    add_column :workspaces, :milestones_achieved_count, :integer, default: 0
    execute("UPDATE workspaces SET milestones_count = 0")
    execute("UPDATE workspaces SET milestones_achieved_count = 0")
  end

  def down
    remove_column :workspaces, :milestones_count
    remove_column :workspaces, :milestones_achieved_count
  end
end
