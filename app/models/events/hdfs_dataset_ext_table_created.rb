require 'events/base'

module Events
  class HdfsDatasetExtTableCreated < Base
    has_targets :dataset, :hdfs_dataset, :workspace
    has_activities :actor, :workspace, :dataset, :hdfs_dataset, :global
  end
end