module Events
  class DataSourceDeleted < Base
    has_targets :data_source
    has_activities :actor, :global
  end
end