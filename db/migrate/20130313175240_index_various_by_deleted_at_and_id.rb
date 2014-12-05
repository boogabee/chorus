class IndexVariousByDeletedAtAndId < ActiveRecord::Migration
  def change
    add_index :datasets, [:deleted_at, :id]
    add_index :users, [:deleted_at, :id]
    add_index :workspaces, [:deleted_at, :id]
  end
end
