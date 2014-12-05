require 'tempfile'
require 'digest/md5'
require 'yaml'
require 'socket'
require_relative './database_integration_helper'

module OracleIntegration
  extend DatabaseIntegrationHelper

  JAR_FILE = Rails.root + 'lib/libraries/ojdbc6.jar'

  def self.versions_file_name
    'oracle_integration_file_versions'
  end

  def self.host_identifier
    'ORACLE_HOST'
  end

  def self.files_to_track
    %w(
      oracle_integration.rb
      drop_oracle_databases.sql.erb
      setup_oracle_databases.sql.erb
    )
  end

  def self.has_jar_file?
    File.exist? JAR_FILE
  end

  require JAR_FILE if self.has_jar_file?

  def self.hostname
    ENV[host_identifier]
  end

  def self.username
    account['db_username']
  end

  def self.password
    account['db_password']
  end

  def self.port
    oracle_config['port']
  end

  def self.db_name
    oracle_config['db_name']
  end

  def self.schema_name
    "test_#{Socket.gethostname.gsub('.', '_').slice(0,14)}_#{Rails.env}".slice(0,30).upcase
  end

  def self.real_data_source
    OracleDataSource.find_by_host(hostname)
  end

  def self.real_account
    real_data_source.owner_account
  end

  def self.real_schema
    real_data_source.schemas.find_by_name(schema_name)
  end

  def self.db_url
    "jdbc:oracle:thin:#{username}/#{password}@//#{hostname}:#{port}/#{db_name}"
  end

  def self.setup_test_schemas
    refresh_if_changed do
      drop_test_database if schema_exists?
      puts "Importing into #{schema_name}"
      sql = ERB.new(File.read(Rails.root.join 'spec/support/database_integration/setup_oracle_databases.sql.erb')).result(binding)
      puts 'Executing setup_oracle_databases.sql'
      execute_sql(sql)
    end
  end

  def self.drop_test_database
    puts "Dropping #{schema_name}"
    sql = ERB.new(File.read(Rails.root.join 'spec/support/database_integration/drop_oracle_databases.sql.erb')).result(binding)
    execute_sql(sql)
  end

  def self.schema_exists?
    Sequel.connect(db_url) do |connection|
      connection.fetch(OracleConnection::SCHEMAS_SQL).any? {|row| row[:name] == schema_name }
    end
  end

  def self.execute_sql(sql)
    Sequel.connect(db_url, :logger => Rails.logger) do |database_connection|
      sql.split(";").each do |line|
        database_connection.run(line) unless line.blank?
      end
    end
  end

  private

  def self.oracle_config
    @@oracle_config ||= find_oracle_data_source hostname
  end

  def self.find_oracle_data_source(name)
    config['data_sources']['oracle'].find { |hash| hash["host"] == name }
  end

  def self.account
    oracle_config['account'] || {}
  end
end

