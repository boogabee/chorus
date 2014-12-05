require 'events/base'

module Events
  class HdfsFileExtTableCreated < Base
    has_targets :dataset, :hdfs_entry, :workspace
    has_activities :actor, :workspace, :dataset, :hdfs_entry, :global
  end
end