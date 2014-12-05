class AddTimeZoneToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :time_zone, :string, :default => 'Alaska'
    execute("UPDATE jobs SET time_zone = 'Alaska'")
  end
end
