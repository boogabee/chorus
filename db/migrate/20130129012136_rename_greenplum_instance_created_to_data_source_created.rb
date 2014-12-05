class RenameGreenplumInstanceCreatedToDataSourceCreated < ActiveRecord::Migration
  def up
    execute "UPDATE events SET action = 'Events::DataSourceCreated', target1_type = 'DataSource' WHERE action='Events::GreenplumInstanceCreated'"
  end

  def down
    execute "UPDATE events SET action = 'Events::GreenplumInstanceCreated', target1_type = 'GpdbDataSource' WHERE action='Events::DataSourceCreated'"
  end
end
