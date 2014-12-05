class ChangeImportsStateToBooleanSuccess < ActiveRecord::Migration
  def up
    add_column :imports, :success, :boolean
    update "UPDATE imports SET success=true WHERE state='success'"
    update "UPDATE imports SET success=false WHERE state='failure'"
    remove_column :imports, :state
  end

  def down
    add_column :imports, :state, :text
    update "UPDATE imports SET state = CASE WHEN success=true THEN 'success' WHEN success=false THEN 'failure' END"
    remove_column :imports, :success
  end
end