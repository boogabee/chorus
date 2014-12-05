class AddPayloadIdToJobTaskResult < ActiveRecord::Migration
  def change
    add_column :job_task_results, :payload_id, :integer
  end
end
