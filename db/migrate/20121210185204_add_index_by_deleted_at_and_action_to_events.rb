class AddIndexByDeletedAtAndActionToEvents < ActiveRecord::Migration
  def change
    add_index :events, [:id, :action, :deleted_at]
    add_index :events, [:id, :action]
    add_index :events, [:id, :deleted_at]
  end
end
