require 'events/base'

module Events
  class WorkspaceArchived < Base
    has_targets :workspace
    has_activities :actor, :workspace
  end
end