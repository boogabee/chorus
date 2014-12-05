require 'events/base'

module Events
  class WorkspaceDeleted < Base
    has_targets :workspace
    has_activities :actor, :global

    def build_activity(entity_name)
      unless entity_name == :global
        super entity_name
        return
      end

      entity = send(:workspace)
      activities.build(:entity_type => Activity::GLOBAL) if entity.public?
    end
  end
end
