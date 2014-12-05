class AddEventIdAndDeletedAtIndexToComments < ActiveRecord::Migration
  def change
    add_index :comments, [:event_id, :deleted_at]
  end
end
