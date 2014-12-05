class ExtendWorkfilesForAlpine < ActiveRecord::Migration
  def up
    update "UPDATE workfiles SET type = 'ChorusWorkfile' WHERE type = 'Workfile'"
    add_column :workfiles, :additional_data, :text
  end

  def down
    update "UPDATE workfiles SET type = 'Workfile' WHERE type = 'ChorusWorkfile'"
    remove_column :workfiles, :additional_data
  end
end
