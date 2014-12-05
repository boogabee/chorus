require 'events/base'

module Events
  class FileImportCreated < ImportCreatedBase
    has_targets :workspace, :dataset
    has_activities :actor, :workspace, :dataset
    has_additional_data :file_name, :import_type, :destination_table, :reference_id, :reference_type

    def self.filter_for_import_events(import)
      where(:workspace_id => import.workspace_id)
    end
  end
end