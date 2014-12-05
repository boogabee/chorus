class RenameMilestoneStatusToState < ActiveRecord::Migration
  def change
    change_table :milestones do |t|
      t.rename :status, :state
    end
  end
end
