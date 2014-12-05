class AddOwnerToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :owner_id, :integer
  end
end
