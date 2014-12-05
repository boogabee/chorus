class RemoveStreamKeyFromImports < ActiveRecord::Migration
  def change
    remove_column :imports, :stream_key
  end
end
