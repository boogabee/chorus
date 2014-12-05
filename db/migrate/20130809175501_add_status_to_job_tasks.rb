class AddStatusToJobTasks < ActiveRecord::Migration
  def change
    add_column :job_tasks, :status, :string
  end
end
