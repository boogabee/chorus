class AddStartedAtToImports < ActiveRecord::Migration
  def change
    add_column :imports, :started_at, :datetime
  end
end
