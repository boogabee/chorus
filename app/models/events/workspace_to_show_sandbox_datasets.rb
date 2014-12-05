require 'events/base'

module Events
  class WorkspaceToShowSandboxDatasets < Base
    has_targets :workspace
    has_activities :actor, :workspace
  end
end