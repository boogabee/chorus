class AddTypeToJobTaskResult < ActiveRecord::Migration
  def change
    add_column :job_task_results, :type, :string
  end
end
