require 'tempfile'
require 'digest/md5'
require 'yaml'

module DatabaseIntegrationHelper

  def host_identifier
    raise 'implement me!'
  end

  def versions_file_name
    raise 'implement me!'
  end

  def files_to_track
    raise 'implement me!'
  end

  def versions_hash
    return {} unless versions_file.exist?
    YAML.load_file(versions_file.to_s)
  end

  def sql_file_hash(file_name)
    full_path = File.expand_path("../#{file_name}",  __FILE__)
    Digest::MD5.hexdigest(File.read(full_path))
  end

  def versions_file
    Pathname.new((File.join(File.dirname(__FILE__), '../../..', "tmp/#{versions_file_name}")).to_s + "_#{ENV['RAILS_ENV']}.yml")
  end

  def watched_files_changed?
    versions = versions_hash
    files_to_track.any? do |file_name|
      versions[file_name.to_s] != sql_file_hash(file_name)
    end || versions[host_identifier] != ENV[host_identifier]
  end

  def refresh_if_changed
    if watched_files_changed?
      yield
      record_changes
    end
  end

  def record_changes
    results_hash = files_to_track.inject({}) do |hash, file_name|
      hash[file_name] = sql_file_hash(file_name)
      hash
    end
    results_hash[host_identifier] = ENV[host_identifier]
    versions_file.open('w') do |f|
      YAML.dump(results_hash, f)
    end
  end

  def config
    config_file = 'test_data_sources_config.yml'
    @@config ||= YAML.load_file(File.join(File.dirname(__FILE__), '../../..', "spec/support/#{config_file}"))
  end
end
