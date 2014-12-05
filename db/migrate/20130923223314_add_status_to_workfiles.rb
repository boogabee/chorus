class AddStatusToWorkfiles < ActiveRecord::Migration
  def up
    add_column :workfiles, :status, :string, :default => 'idle'
    execute("UPDATE workfiles SET status = 'idle'")
  end

  def down
    remove_column :workfiles, :status
  end
end
