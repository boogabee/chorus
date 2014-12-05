class UpdateProjectsToBeOnTrack < ActiveRecord::Migration
  def up
    execute("UPDATE workspaces SET project_status = 'on_track'")
  end

  def down
  end
end
