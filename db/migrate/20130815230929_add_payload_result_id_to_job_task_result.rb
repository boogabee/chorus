class AddPayloadResultIdToJobTaskResult < ActiveRecord::Migration
  def change
    add_column :job_task_results, :payload_result_id, :string
  end
end
