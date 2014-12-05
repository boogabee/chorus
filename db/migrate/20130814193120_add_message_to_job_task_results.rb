class AddMessageToJobTaskResults < ActiveRecord::Migration
  def change
    add_column :job_task_results, :message, :text
  end
end
