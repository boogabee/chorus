class FixCsvImports < ActiveRecord::Migration
  def up
    update "UPDATE imports SET type = 'CsvImport' WHERE file_name IS NOT NULL"
  end
end
