class EncryptInstanceAccountPasswords < ActiveRecord::Migration
  def up
    add_column :instance_accounts, :encrypted_db_password, :string
    remove_column :instance_accounts, :db_password
  end

  def down
    add_column :instance_accounts, :db_password, :string
    remove_column :instance_accounts, :encrypted_db_password
  end
end
