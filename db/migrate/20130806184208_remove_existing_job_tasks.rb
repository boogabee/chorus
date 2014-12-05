class RemoveExistingJobTasks < ActiveRecord::Migration
  def up
    execute("DELETE FROM job_tasks")
  end

  def down
  end
end
