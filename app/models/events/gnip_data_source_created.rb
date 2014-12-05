require 'events/base'

module Events
  class GnipDataSourceCreated < Base
    has_targets :gnip_data_source
    has_activities :actor, :gnip_data_source, :global
  end
end