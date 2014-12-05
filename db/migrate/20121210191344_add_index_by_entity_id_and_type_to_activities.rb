class AddIndexByEntityIdAndTypeToActivities < ActiveRecord::Migration
  def change
    add_index :activities, [:entity_id, :entity_type]
  end
end
