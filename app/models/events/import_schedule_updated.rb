require 'events/base'

module Events
  class ImportScheduleUpdated < Base
    has_targets :source_dataset, :dataset, :workspace
    has_activities :actor, :workspace, :dataset, :source_dataset
    has_additional_data :destination_table
  end
end