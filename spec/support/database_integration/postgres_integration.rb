require 'socket'
require_relative './database_integration_helper'

module PostgresIntegration
  extend DatabaseIntegrationHelper

  def self.versions_file_name
    'postgres_integration_file_versions'
  end

  def self.files_to_track
    %w(
      postgres_integration.rb
      setup_postgres_database.sql.erb
      setup_postgres_contents.sql.erb
    )
  end

  def self.host_identifier
    'PG_HOST'
  end

  def self.hostname
    ENV[host_identifier]
  end

  def self.data_source_config
    {
        :name => hostname,
        :host => hostname,
        :port => port,
        :db_name => db_name,
        :db_username => username,
        :db_password => password
    }
  end

  def self.username
    account_config['db_username']
  end

  def self.password
    account_config['db_password']
  end

  def self.port
    pg_config['port']
  end

  def self.db_name
    pg_config['db_name']
  end

  def self.database_name
    @database_name ||= "test_#{Socket.gethostname.gsub('.', '_').slice(0,14)}_#{Rails.env}".slice(0,30).downcase
  end

  def self.schema_name
    'test_schema'
  end

  def self.real_data_source
    PgDataSource.find_by_name(hostname)
  end

  def self.real_account
    real_data_source.owner_account
  end

  def self.real_database(db=database_name)
    real_data_source.databases.find_by_name!(db)
  end

  def self.real_database_priv
    real_database("#{database_name}_priv")
  end

  def self.db_url(db=nil)
    db = db_name unless db
    "jdbc:postgresql://#{hostname}:#{port}/#{db}"
  end

  def self.execute_sql(sql, database='postgres')
    options = {
        :user => username,
        :password => password,
        :logger => Rails.logger
    }

    Sequel.connect(db_url(database), options) { |connection| connection.run(sql) }
    true
  rescue Exception => e
    puts e.message
    false
  end

  def self.execute_sql_file(sql_file, database='postgres')
    puts "Executing SQL file: #{sql_file} into #{database} on host #{hostname}"
    sql_erb = ERB.new(File.read(File.expand_path("../#{sql_file}.erb", __FILE__)))

    sql = sql_erb.result(binding)
    execute_sql(sql, database)
  end

  def self.drop_test_database
    execute_sql(%(DROP DATABASE IF EXISTS "#{database_name}";))
  end

  def self.setup
    refresh_if_changed do
      drop_test_database
      success = execute_sql_file 'setup_postgres_database.sql'
      success &&= execute_sql_file 'setup_postgres_contents.sql', database_name

      raise 'Postgres fixture building failed' unless success
    end
  end

  def self.refresh
    account = real_account
    PgDatabase.refresh(account)
    database = PgDatabase.find_by_name(database_name)
    PgSchema.refresh(account, database)
    schema = database.schemas.find_by_name(schema_name)
    schema.refresh_datasets(account)

    schema3 = database.schemas.find_by_name('test_schema3')
    schema3.refresh_datasets(account)

    database_priv = PgDatabase.find_by_name("#{database_name}_priv")
    PgSchema.refresh(account, database_priv)
  end

  def self.account_config
    pg_config['account']
  end

  private

  def self.pg_config
    @@pg_config ||= find_pg(hostname)
  end

  def self.find_pg(id)
    config['data_sources']['postgres'].find { |hash| hash['host'] == id }
  end
end

