class RenameFileContainsHeaderToHasHeaderOnCsvFiles < ActiveRecord::Migration
  def change
    rename_column :csv_files, :file_contains_header, :has_header
  end
end
