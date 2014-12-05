chorus_home = File.expand_path(File.dirname(__FILE__) + '/../')
require File.join(chorus_home, 'app', 'models', 'chorus_config')

chorus_config = ChorusConfig.new(chorus_home)

puts "export CHORUS_NEWRELIC_ENABLED=#{chorus_config["newrelic.enabled"]}"
puts "export CHORUS_NEWRELIC_LICENSE_KEY=\"#{chorus_config["newrelic.license_key"]}\""
