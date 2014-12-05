require 'events/base'

module Events
  class DataSourceChangedName < Base
    has_targets :data_source
    has_additional_data :old_name, :new_name
    has_activities :actor, :data_source, :global
  end
end