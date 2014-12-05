class RemoveImportIdFromDatasets < ActiveRecord::Migration
  def up
    remove_column :datasets, :import_id
  end

  def down
    add_column :datasets, :import_id, :integer
  end
end
