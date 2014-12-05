require 'events/base'

module Events
  class DataSourceChangedOwner < Base
    has_targets :data_source, :new_owner
    has_activities :data_source, :new_owner, :global
  end
end