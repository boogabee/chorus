class RenameInstanceIdToDataSourceIdOnInstanceAccounts < ActiveRecord::Migration
  def change
    rename_column :instance_accounts, :instance_id, :data_source_id
    rename_index :instance_accounts, 'index_instance_accounts_on_instance_id', 'index_instance_accounts_on_data_source_id'
  end
end
