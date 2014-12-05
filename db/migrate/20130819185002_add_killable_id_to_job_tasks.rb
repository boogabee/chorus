class AddKillableIdToJobTasks < ActiveRecord::Migration
  def change
    add_column :job_tasks, :killable_id, :integer
  end
end
