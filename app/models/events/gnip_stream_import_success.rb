require 'events/base'

module Events
  class GnipStreamImportSuccess < Base
    has_targets :gnip_data_source, :dataset, :workspace
    has_activities :workspace, :dataset, :gnip_data_source
  end
end