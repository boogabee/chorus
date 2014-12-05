class AddEndRunDateToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :end_run, :timestamp
  end
end
