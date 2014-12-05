class AddNullConstraintsToHadoopInstances < ActiveRecord::Migration
  def change
    change_column :hadoop_instances, :host, :string, :null => false
    change_column :hadoop_instances, :port, :integer, :null => false
  end
end
