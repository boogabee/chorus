require "tempfile"
require 'digest/md5'
require 'yaml'
require 'socket'

module HdfsIntegration
  HOST = ENV['HADOOP_HOST']

  def self.data_source_config(name = HOST)
    config['data_sources']['hadoop'].find { |hash| hash["host"] == name }
  end

  private

  def self.config
    config_file = "test_data_sources_config.yml"
    @@config ||= YAML.load_file(File.join(File.dirname(__FILE__), '../../..', "spec/support/#{config_file}"))
  end
end