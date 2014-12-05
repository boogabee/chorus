require 'events/base'

module Events
  class WorkspaceAddSandbox < Base
    has_targets :workspace
    has_activities :actor, :workspace
  end
end