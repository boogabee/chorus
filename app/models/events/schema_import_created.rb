require 'events/base'

module Events
  class SchemaImportCreated < ImportCreatedBase
    has_targets :source_dataset, :dataset, :schema
    has_activities :actor, :dataset, :source_dataset
    has_additional_data :destination_table, :reference_type, :reference_id

    def self.filter_for_import_events(import)
      where(:target1_id => import.source_id, :target1_type => import.source_type)
    end
  end
end