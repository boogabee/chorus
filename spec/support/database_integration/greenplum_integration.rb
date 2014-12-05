require 'tempfile'
require 'digest/md5'
require 'yaml'
require 'socket'
require_relative './database_integration_helper'

module GreenplumIntegration
  extend DatabaseIntegrationHelper

  def self.versions_file_name
    'data_source_integration_file_versions'
  end

  def self.host_identifier
    'GPDB_HOST'
  end

  def self.files_to_track
    %w(
      greenplum_integration.rb
      create_users.sql.erb
      drop_and_create_gpdb_databases.sql.erb
      create_test_schemas.sql.erb
      create_private_test_schema.sql.erb
      drop_public_schema.sql.erb
    )
  end

  def self.execute_sql_file(sql_file, database = greenplum_config['db_name'])
    puts "Executing SQL file: #{sql_file} into #{database} on host: #{hostname}"
    sql_erb = ERB.new(File.read(File.expand_path("../#{sql_file}.erb", __FILE__)))

    sql = sql_erb.result(binding)
    execute_sql(sql, database)
  end

  def self.execute_sql(sql, database = nil, &blk)
    database = database_name unless database
    database_string = "jdbc:postgresql://#{hostname}:#{port}/#{database}"
    options = {:user => username, :password => password}
    options[:jdbc_properties] = {
        sslmode: 'require'
    } if ssl
    if block_given?
      return Sequel.connect(database_string, options, &blk)
    else
      Sequel.connect(database_string, options) do |database_connection|
        database_connection.run(sql)
      end
      return true
    end
  rescue Exception => e
    puts e.message
    return false
  end

  def self.exec_sql_line_with_results(sql)
    execute_sql(sql) do |database_connection|
      database_connection.fetch(sql).all
    end
  end

  def self.drop_test_db
    execute_sql(%(DROP DATABASE IF EXISTS "#{GreenplumIntegration.database_name}"))
    execute_sql(%(DROP DATABASE IF EXISTS "#{sandbox_created_db}"))
  end

  def self.setup_gpdb
    refresh_if_changed do
      puts "  Importing into #{GreenplumIntegration.database_name}"
      drop_test_db
      execute_sql_file("create_users.sql")
      success = execute_sql_file("drop_and_create_gpdb_databases.sql")
      success &&= execute_sql_file("create_test_schemas.sql", database_name)
      success &&= execute_sql_file("create_private_test_schema.sql", "#{database_name}_priv")
      success &&= execute_sql_file("create_test_schemas.sql", "#{database_name}_wo_pub")
      success &&= execute_sql_file("drop_public_schema.sql", "#{database_name}_wo_pub")
      raise "Unable to add test data to #{GreenplumIntegration.hostname}" unless success
    end
  end

  def self.database_name
    "gpdb_#{Socket.gethostname.gsub('.', '_').slice(0, 14)}_#{ENV['RAILS_ENV']}".slice(0, 26) # needs to fit in 31 characters with _priv appended
  end

  def self.data_source_config(name)
    config = find_greenplum_data_source name
    account_config = config['account']
    config.reject { |k, v| k == "account" }.merge(account_config)
  end

  def self.account_config(name)
    find_greenplum_data_source(name)['account']
  end

  def self.refresh_chorus
    GreenplumIntegration.setup_gpdb

    account = GreenplumIntegration.real_account
    GpdbDatabase.refresh(account)

    database = GpdbDatabase.find_by_name(GreenplumIntegration.database_name)
    GpdbSchema.refresh(account, database)
    gpdb_schema = database.schemas.find_by_name('test_schema')
    gpdb_schema.refresh_datasets(account)

    database_without_public_schema = GpdbDatabase.find_by_name("#{GreenplumIntegration.database_name}_priv")
    GpdbSchema.refresh(account, database_without_public_schema)
    gpdb_schema_without_public_schema = database_without_public_schema.schemas.find_by_name('non_public_schema')
    gpdb_schema_without_public_schema.refresh_datasets(account)

    account
  end

  def refresh_chorus
    GreenplumIntegration.refresh_chorus
  end

  def self.hostname
    ENV[host_identifier]
  end

  def self.real_account
    gpdb_data_source = GreenplumIntegration.real_data_source
    gpdb_data_source.owner_account
  end

  def self.real_data_source
    #GpdbDataSource.find_by_name(hostname) works 99% of the time, but fails with a mysterious 'type IN (0)' error 1% of the time
    GpdbDataSource.find_by_sql(%Q{SELECT  "data_sources".* FROM "data_sources"  WHERE "data_sources"."name" = '#{hostname}' LIMIT 1}).first
  end

  def self.real_database
    real_data_source.databases.find_by_name!(self.database_name)
  end

  def self.username
    greenplum_account['db_username']
  end

  def self.password
    greenplum_account['db_password']
  end

  def self.port
    greenplum_config['port']
  end

  def self.ssl
    greenplum_config['ssl']
  end

  def self.sandbox_created_db
    "sand_db_#{Rails.env}"
  end

  private

  def self.greenplum_config
    @@gp_config ||= find_greenplum_data_source hostname
  end

  def self.find_greenplum_data_source(name)
    config['data_sources']['gpdb'].find { |hash| hash["host"] == name }
  end

  def self.greenplum_account
    greenplum_config['account'] || {}
  end
end

