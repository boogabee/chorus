require 'yaml'

environment = ENV['RAILS_ENV']

chorus_home = File.expand_path(File.dirname(__FILE__) + '/../')
require File.join(chorus_home, 'app/models/chorus_config')

chorus_config = ChorusConfig.new(chorus_home)

database_yml = File.join(chorus_home, 'config', 'database.yml')
db_config = YAML.load_file database_yml

pool_size = [chorus_config['webserver_threads'].to_i, (chorus_config['worker_threads'].to_i + 1)].max
postgres_port = chorus_config['postgres_port']

if db_config[environment] && (db_config[environment]['pool'] != pool_size || db_config[environment]['port'] != postgres_port)
  db_config[environment]['pool'] = pool_size
  db_config[environment]['port'] = postgres_port

  File.open(database_yml, 'w') do |f|
    f.write(YAML.dump(db_config))
  end
end
