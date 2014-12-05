chorus_home = File.expand_path(File.dirname(__FILE__) + '/../')
require 'rexml/document'
require File.join(chorus_home, 'app/models/chorus_config')

jetty_xml_file = File.join(chorus_home, 'vendor', 'jetty', 'jetty.xml')

chorus_config = ChorusConfig.new(chorus_home)

xml_doc = REXML::Document.new(File.new(jetty_xml_file))
max_threads = REXML::XPath.first(xml_doc, "/Configure/Set[@name='ThreadPool']/New/Set[@name='maxThreads']")
max_threads.text = chorus_config['webserver_threads']

min_threads = REXML::XPath.first(xml_doc, "/Configure/Set[@name='ThreadPool']/New/Set[@name='minThreads']")
if min_threads.text.to_i > chorus_config['webserver_threads'].to_i
  min_threads.text = chorus_config['webserver_threads']
end

File.open(jetty_xml_file, 'w') do |f|
  f.write(xml_doc.to_s)
end