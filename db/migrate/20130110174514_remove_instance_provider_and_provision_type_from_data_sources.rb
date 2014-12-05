class RemoveInstanceProviderAndProvisionTypeFromDataSources < ActiveRecord::Migration
  def up
    remove_column :data_sources, :instance_provider
    remove_column :data_sources, :provision_type
  end

  def down
    add_column :data_sources, :instance_provider, :string, :length => 256
    add_column :data_sources, :provision_type, :string, :length => 256
  end
end
