class AddFileNameToImports < ActiveRecord::Migration
  def change
    add_column :imports, :file_name, :text
  end
end
