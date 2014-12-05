class PgDataSource < ConcreteDataSource
  include PostgresLikeDataSourceBehavior
  include DataSourceWithSandbox

  has_many :databases, :foreign_key => 'data_source_id', :class_name => 'PgDatabase'

  def self.create_for_user(user, data_source_hash)
    user.pg_data_sources.create!(data_source_hash, :as => :create)
  end

  def data_source_provider
    'PostgreSQL Database'
  end

  def cancel_imports
    #no-op until has imports
  end
end
