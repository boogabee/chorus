class AddStateToImports < ActiveRecord::Migration
  def change
    add_column :imports, :state, :text
  end
end
