require 'events/base'

module Events
  class WorkspaceToNoLongerShowSandboxDatasets < Base
    has_targets :workspace
    has_activities :actor, :workspace
  end
end