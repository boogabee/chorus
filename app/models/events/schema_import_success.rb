require 'events/base'

module Events
  class SchemaImportSuccess < Base
    has_targets :source_dataset, :dataset
    has_activities :actor, :dataset, :source_dataset
  end
end