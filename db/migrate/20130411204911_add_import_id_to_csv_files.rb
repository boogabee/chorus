class AddImportIdToCsvFiles < ActiveRecord::Migration
  def change
    add_column :csv_files, :import_id, :integer
  end
end
