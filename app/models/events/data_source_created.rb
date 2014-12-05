require 'events/base'

module Events
  class DataSourceCreated < Base
    has_targets :data_source
    has_activities :actor, :data_source, :global
  end
end