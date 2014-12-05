require 'events/base'

module Events
  class GnipStreamImportFailed < Base
    has_targets :gnip_data_source, :workspace
    has_activities :workspace, :gnip_data_source
    has_additional_data :destination_table, :error_message
  end
end