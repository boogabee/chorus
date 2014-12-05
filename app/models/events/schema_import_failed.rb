require 'events/base'

module Events
  class SchemaImportFailed < Base
    has_targets :source_dataset, :dataset, :schema
    has_activities :actor, :source_dataset, :dataset
    has_additional_data :destination_table, :error_message
  end
end