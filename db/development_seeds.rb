load Rails.root.join('db', 'seeds.rb')

gpdb_host = ENV['GPDB_HOST']
oracle_host = ENV['ORACLE_HOST']
hadoop_host = ENV['HADOOP_HOST']

if gpdb_host || oracle_host || hadoop_host
  data_source_configs = YAML.load_file(File.join(File.dirname(__FILE__), '..', "spec/support/test_data_sources_config.yml"))['data_sources']

  chorus_admin = User.where(:username => 'chorusadmin').first

  if gpdb_host && GpdbDataSource.where(:host => gpdb_host).count == 0
    gpdb_config = data_source_configs['gpdb'].find { |hash| hash['host'] == gpdb_host }.merge(:name => gpdb_host)
    gpdb_config.merge!(gpdb_config['account'])
    puts "Creating Greenplum connection #{gpdb_host}"
    GpdbDataSource.create_for_user(chorus_admin, gpdb_config)
  end

  if oracle_host && OracleDataSource.where(:host => oracle_host).count == 0
    oracle_config = data_source_configs['oracle'].find { |hash| hash['host'] == oracle_host }.merge(:name => oracle_host)
    oracle_config.merge!(oracle_config['account'])
    puts "Creating Oracle connection #{oracle_host}"
    OracleDataSource.create_for_user(chorus_admin, oracle_config)
  end

  if hadoop_host && HdfsDataSource.where(:host => hadoop_host).count == 0
    hadoop_config = data_source_configs['hadoop'].find { |hash| hash['host'] == hadoop_host }
    hadoop_config.delete 'adapter_version'
    puts "Creating HDFS connection #{hadoop_host}"
    HdfsDataSource.create!(hadoop_config.merge(:name => hadoop_host, :owner => chorus_admin), :without_protection => true)
  end
end