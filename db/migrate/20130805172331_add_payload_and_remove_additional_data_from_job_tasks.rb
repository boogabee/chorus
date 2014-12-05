class AddPayloadAndRemoveAdditionalDataFromJobTasks < ActiveRecord::Migration
  def up
    remove_column :job_tasks, :additional_data
    add_column :job_tasks, :payload_id, :integer
    add_column :job_tasks, :payload_type, :string
  end

  def down
    remove_column :job_tasks, :payload_id
    remove_column :job_tasks, :payload_type
    add_column :job_tasks, :additional_data, :text
  end
end
