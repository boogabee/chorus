class AddIndexByEventIdToActivities < ActiveRecord::Migration
  def change
    add_index :activities, :event_id
  end
end
