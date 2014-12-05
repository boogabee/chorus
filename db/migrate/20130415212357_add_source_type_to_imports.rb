class AddSourceTypeToImports < ActiveRecord::Migration
  def up
    add_column :imports, :source_type, :string
    execute "UPDATE imports SET source_type='Dataset' WHERE source_dataset_id IS NOT NULL"
    rename_column :imports, :source_dataset_id, :source_id
  end

  def down
    remove_column :imports, :source_type, :string
    rename_column :imports, :source_id, :source_dataset_id
  end
end
