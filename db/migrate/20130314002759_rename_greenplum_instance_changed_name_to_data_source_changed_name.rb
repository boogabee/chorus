class RenameGreenplumInstanceChangedNameToDataSourceChangedName < ActiveRecord::Migration
  def up
    execute "UPDATE events SET action='Events::DataSourceChangedName' WHERE action='Events::GreenplumInstanceChangedName'"
  end

  def down
    execute "UPDATE events SET action='Events::GreenplumInstanceChangedName' WHERE action='Events::DataSourceChangedName'"
  end
end
