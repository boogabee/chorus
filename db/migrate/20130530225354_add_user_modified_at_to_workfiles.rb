class AddUserModifiedAtToWorkfiles < ActiveRecord::Migration
  class MigrationWorkfile < ActiveRecord::Base
    self.table_name = :workfiles
  end

  def up
    add_column :workfiles, :user_modified_at, :datetime
    execute "update workfiles set user_modified_at = updated_at"
  end

  def down
    remove_column :workfiles, :user_modified_at
  end
end
