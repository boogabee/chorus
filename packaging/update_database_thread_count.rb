chorus_home = File.expand_path(File.dirname(__FILE__) + '/../')
#require File.join(chorus_home, 'config', 'boot')
require File.join(chorus_home, 'app', 'models', 'chorus_config')

chorus_config = ChorusConfig.new(chorus_home)
max_connections = chorus_config["database_threads"]

print max_connections