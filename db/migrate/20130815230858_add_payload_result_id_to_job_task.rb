class AddPayloadResultIdToJobTask < ActiveRecord::Migration
  def change
    add_column :job_tasks, :payload_result_id, :string
  end
end
