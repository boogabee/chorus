class RenameAccountGpdbInstanceIdToInstanceId < ActiveRecord::Migration
  def change
    rename_column :instance_accounts, :gpdb_instance_id, :instance_id
  end
end
