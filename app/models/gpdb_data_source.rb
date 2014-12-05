class GpdbDataSource < ConcreteDataSource
  include PostgresLikeDataSourceBehavior
  include DataSourceWithSandbox

  has_many :databases, :foreign_key => 'data_source_id', :class_name => 'GpdbDatabase'

  has_many :imports_as_source, :through => :datasets, :source => :imports
  has_many :imports_as_destination_via_schema, :through => :schemas, :source => :imports
  has_many :imports_as_destination_via_workspace, :through => :schemas, :source => :imports_via_workspaces

  def self.create_for_user(user, data_source_hash)
    user.gpdb_data_sources.create!(data_source_hash, :as => :create)
  end

  def data_source_provider
    'Greenplum Database'
  end

  private

  def cancel_imports
    imports_as_source.unfinished.each do |import|
      import.cancel(false, "Source/Destination of this import was deleted")
    end
    imports_as_destination_via_schema.unfinished.each do |import|
      import.cancel(false, "Source/Destination of this import was deleted")
    end
    imports_as_destination_via_workspace.unfinished.each do |import|
      import.cancel(false, "Source/Destination of this import was deleted")
    end
  end

  def connection_class
    GreenplumConnection
  end
end
