class AddCanceledAtAndCancelMessageToImports < ActiveRecord::Migration
  def change
    add_column :imports, :canceled_at, :timestamp
    add_column :imports, :cancel_message, :string
  end
end
