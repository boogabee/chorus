class RemoveSaltFromInstanceAccount < ActiveRecord::Migration
  def up
    remove_column :instance_accounts, :salt
  end

  def down
    add_column :instance_accounts, :salt, :string
  end
end
