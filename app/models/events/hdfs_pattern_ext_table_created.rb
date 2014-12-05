require 'events/base'

module Events
  class HdfsPatternExtTableCreated < Base
    has_targets :dataset, :hdfs_entry, :workspace
    has_activities :actor, :workspace, :dataset, :hdfs_entry, :global
    has_additional_data :file_pattern
  end
end