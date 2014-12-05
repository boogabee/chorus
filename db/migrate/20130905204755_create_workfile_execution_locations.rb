class CreateWorkfileExecutionLocations < ActiveRecord::Migration
  def change
    create_table :workfile_execution_locations do |t|
      t.references :workfile, polymorphic: true
      t.references :execution_location, polymorphic: true
    end

    add_index :workfile_execution_locations, :workfile_id
  end
end
