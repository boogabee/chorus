class RemoveUniquenessValidationForAssociatedDataset < ActiveRecord::Migration
  def up
    change_table :associated_datasets do |t|
      t.remove_index :name => 'gpdb_db_object_workspace_unique'
      t.index [:dataset_id, :workspace_id]
    end
  end

  def down
    change_table :associated_datasets do |t|
      t.remove_index :column => [:dataset_id, :workspace_id]
      t.index [:dataset_id, :workspace_id], :unique => true, :name => 'gpdb_db_object_workspace_unique'
    end
  end
end
