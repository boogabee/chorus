class CreateJobTasks < ActiveRecord::Migration
  def change
    create_table :job_tasks do |t|
      t.string :name
      t.integer :index
      t.string :action
      t.timestamp :deleted_at
      t.belongs_to :job

      t.timestamps
    end
  end
end
