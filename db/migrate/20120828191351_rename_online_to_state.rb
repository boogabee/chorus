class RenameOnlineToState < ActiveRecord::Migration
  class MigrationInstance < ActiveRecord::Base
    self.table_name = :gpdb_instances
  end

  def up
    add_column :gpdb_instances, :state, :string, :default => 'online'
    MigrationInstance.reset_column_information

    MigrationInstance.update_all(:state => 'online')
    MigrationInstance.where("online = false").update_all(:state => 'offline')

    remove_column :gpdb_instances, :online
  end

  def down
    add_column :gpdb_instances, :online, :boolean, :default => true
    MigrationInstance.reset_column_information

    MigrationInstance.where("state <> 'online'").update_all(:online => false)

    remove_column :gpdb_instances, :state
  end
end
