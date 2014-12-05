module Events
  class WorkfileResult < Base
    has_targets :workfile
    has_activities :actor, :workfile, :workspace
  end
end