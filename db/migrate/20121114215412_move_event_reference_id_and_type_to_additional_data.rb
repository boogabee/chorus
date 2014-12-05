class MoveEventReferenceIdAndTypeToAdditionalData < ActiveRecord::Migration
  def up
    remove_column :events, :reference_id
    remove_column :events, :reference_type
  end

  def down
    add_column :events, :reference_id, :integer
    add_column :events, :reference_type, :string
  end
end
