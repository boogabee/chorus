class AddSaltToInstanceAccounts < ActiveRecord::Migration
  def up
    add_column :instance_accounts, :salt, :string
  end

  def down
    remove_column :instance_accounts, :salt
  end

end
