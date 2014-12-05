class AddInvalidCredentialsFlagToInstanceAccounts < ActiveRecord::Migration
  def change
    add_column :instance_accounts, :invalid_credentials, :boolean
  end
end
