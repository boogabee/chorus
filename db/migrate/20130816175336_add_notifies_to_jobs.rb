class AddNotifiesToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :notifies, :boolean, :default => false
  end
end
