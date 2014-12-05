require 'events/base'

module Events
  class WorkspaceImportCreated < ImportCreatedBase
    has_targets :source_dataset, :dataset, :workspace
    has_activities :actor, :workspace, :dataset, :source_dataset
    has_additional_data :destination_table, :reference_id, :reference_type

    def self.filter_for_import_events(import)
      where(:target1_id => import.source_id,
            :target1_type => import.source_type,
            :workspace_id => import.workspace_id)
    end
  end
end