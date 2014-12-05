class ChangeKillableIdToString < ActiveRecord::Migration
  def up
    change_column :job_tasks, :killable_id, :string
  end

  def down
    change_column :job_tasks, :killable_id, :integer
  end
end
