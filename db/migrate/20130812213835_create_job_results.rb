class CreateJobResults < ActiveRecord::Migration
  def change
    create_table :job_results do |t|
      t.integer :job_id
      t.timestamp :started_at
      t.timestamp :finished_at
      t.boolean :succeeded

      t.timestamps
    end
  end
end
