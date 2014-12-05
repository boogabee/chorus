class AddSslToDataSources < ActiveRecord::Migration
  def up
    add_column :data_sources, :ssl, :boolean, :default => false
    execute("UPDATE data_sources SET ssl = false")
  end

  def down
    remove_column :data_sources, :ssl
  end
end
