class AddTypeToJobTasks < ActiveRecord::Migration
  def change
    add_column :job_tasks, :type, :string
  end
end
