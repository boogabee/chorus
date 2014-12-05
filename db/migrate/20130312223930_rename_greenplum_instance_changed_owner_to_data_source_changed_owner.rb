class RenameGreenplumInstanceChangedOwnerToDataSourceChangedOwner < ActiveRecord::Migration
  def up
    execute "UPDATE events SET action='Events::DataSourceChangedOwner' WHERE action='Events::GreenplumInstanceChangedOwner'"
  end

  def down
    execute "UPDATE events SET action='Events::GreenplumInstanceChangedOwner WHERE action='Events::DataSourceChangedOwner'"
  end
end
