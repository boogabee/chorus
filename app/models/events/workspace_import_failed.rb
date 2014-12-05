require 'events/base'

module Events
  class WorkspaceImportFailed < Base
    has_targets :source_dataset, :dataset, :workspace
    has_activities :actor, :workspace, :source_dataset, :dataset
    has_additional_data :destination_table, :error_message, :error_objects
  end
end
