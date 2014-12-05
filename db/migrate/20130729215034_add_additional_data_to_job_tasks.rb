class AddAdditionalDataToJobTasks < ActiveRecord::Migration
  def change
    add_column :job_tasks, :additional_data, :text
  end
end
