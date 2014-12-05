class AddFrequencyAndNextRunToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :frequency, :string
    add_column :jobs, :next_run, :timestamp
    add_column :jobs, :last_run, :timestamp
  end
end
