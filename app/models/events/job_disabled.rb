module Events
  class JobDisabled < Base
    has_targets :job, :workspace
    has_activities :job, :workspace
  end
end
