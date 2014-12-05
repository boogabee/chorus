class JdbcDataSource < DataSource
  include SingleLevelDataSourceBehavior

  alias_attribute :url, :host

  has_many :schemas, :as => :parent, :class_name => 'JdbcSchema'
  has_many :datasets, :through => :schemas
  has_many :workfile_execution_locations, :foreign_key => :execution_location_id, :conditions => { :execution_location_type => 'DataSource' }, :dependent => :destroy

  def self.create_for_user(user, data_source_hash)
    user.jdbc_data_sources.create!(data_source_hash, :as => :create)
  end

  private

  def connection_class
    JdbcConnection
  end

  def cancel_imports
    #no-op
  end

  def enqueue_destroy_schemas
    QC.enqueue_if_not_queued('JdbcSchema.destroy_schemas', id)
  end
end