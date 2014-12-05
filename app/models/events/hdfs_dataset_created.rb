require 'events/base'

module Events
  class HdfsDatasetCreated < Base
    has_targets :dataset, :hdfs_data_source, :workspace
    has_activities :actor, :workspace, :dataset, :hdfs_data_source
  end
end
