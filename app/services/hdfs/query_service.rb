require 'timeout'

require Rails.root.join('vendor/hadoop/hdfs-query-service-0.0.11.jar')

module Hdfs
  include Chorus

  PREVIEW_LINE_COUNT = 200
  DirectoryNotFoundError = Class.new(StandardError)
  FileNotFoundError = Class.new(StandardError)

  JavaHdfs = com.emc.greenplum.hadoop.Hdfs
  JavaHdfs.timeout = 5

  class QueryService
    def self.version_of(data_source)
      self.for_data_source(data_source).version
    end

    def self.accessible?(data_source)
      self.for_data_source(data_source).java_hdfs.list('/').present?
    end

    def self.for_data_source(data_source)
      new(data_source.host, data_source.port, data_source.username, data_source.version, data_source.high_availability?, data_source.hdfs_pairs)
    end

    def initialize(host, port, username, version = nil, high_availability = false, connection_parameters = [])
      @host = host
      @port = port.to_s
      @username = username
      @version = version
      @high_availability = high_availability
      @connection_parameters = connection_parameters
    end

    def version
      version = java_hdfs.version
      unless version
        Chorus.log_error "Within JavaHdfs connection, failed to establish connection to #{@host}:#{@port}"
        raise ApiValidationError.new(:connection, :generic, {:message => "Unable to determine HDFS server version or unable to reach server at #{@host}:#{@port}. Check connection parameters."})
      end
      version.get_name
    end

    def list(path)
      list = java_hdfs.list(path)
      raise DirectoryNotFoundError, "Directory does not exist: #{path}" unless list
      list.map do |object|
        {
          'path' => object.path,
          'modified_at' => object.modified_at,
          'is_directory' => object.is_directory,
          'size' => object.size,
          'content_count' => object.content_count
        }
      end
    end

    def details(path)
      stats = java_hdfs.details(path)
      raise FileNotFoundError, "File not found on HDFS: #{path}" unless stats
      stats
    end

    def show(path)
      contents = java_hdfs.content(path, PREVIEW_LINE_COUNT)
      raise FileNotFoundError, "File not found on HDFS: #{path}" unless contents
      contents
    end

    def delete(path)
      java_hdfs.delete(path)
    end

    def import_data(path, stream, opts={})
      opts  = {:overwrite => false}.merge opts
      wrapped_result = java_hdfs.import_data(path, stream, opts[:overwrite])
      wrapped_result.success? || (raise StandardError.new unwrap_message(wrapped_result))
    end

    def java_hdfs
      JavaHdfs.new(@host, @port, @username, @version, @high_availability, @connection_parameters)
    end

    private

    def unwrap_message(wrapped_result)
      wrapped_result.message.each_line.first.strip unless wrapped_result.message.nil?
    end
  end
end
