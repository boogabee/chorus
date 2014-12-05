class AddStreamKeyToImports < ActiveRecord::Migration
  def change
    add_column :imports, :stream_key, :string, :length => 40
  end
end
