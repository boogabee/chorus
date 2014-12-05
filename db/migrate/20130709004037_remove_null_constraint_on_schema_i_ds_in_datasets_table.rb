class RemoveNullConstraintOnSchemaIDsInDatasetsTable < ActiveRecord::Migration
  def up
    change_column :datasets, :schema_id, :integer, :null => true
  end

  def down
    change_column :datasets, :schema_id, :integer, :null => false
  end
end
