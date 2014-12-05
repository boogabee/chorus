class CreateJobTaskResults < ActiveRecord::Migration
  def change
    create_table :job_task_results do |t|
      t.integer :job_result_id
      t.string :name
      t.timestamp :started_at
      t.timestamp :finished_at
      t.string :status

      t.timestamps
    end
  end
end
