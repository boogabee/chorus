require 'events/base'

module Events
  class HdfsDataSourceChangedName < Base
    has_targets :hdfs_data_source
    has_additional_data :old_name, :new_name
    has_activities :actor, :hdfs_data_source, :global
  end
end

