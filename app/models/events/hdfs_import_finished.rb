require 'events/base'

module Events
  class HdfsImportFinished < Base
    has_targets :hdfs_entry, :hdfs_data_source
    has_activities :actor, :hdfs_entry, :hdfs_data_source
    has_additional_data :file_name
  end
end
