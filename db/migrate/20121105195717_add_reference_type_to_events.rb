class AddReferenceTypeToEvents < ActiveRecord::Migration
  def change
    add_column :events, :reference_type, :string
  end
end
