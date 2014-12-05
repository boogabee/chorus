class RenameInstanceAccounts < ActiveRecord::Migration
  def change
    rename_table :instance_accounts, :data_source_accounts
    rename_table :instance_account_permissions, :data_source_account_permissions
    rename_column :data_source_account_permissions, :instance_account_id, :data_source_account_id
  end
end
