class RemoveNameFromJobTasks < ActiveRecord::Migration
  def up
    remove_column :job_tasks, :name
  end

  def down
    add_column :job_tasks, :name, :string
  end
end
