require 'events/base'

module Events
  class ProjectStatusChanged < Base
    has_targets :workspace
    has_activities :actor, :workspace
    has_additional_data :status, :reason

    before_validation :adopt_status_and_reason
    validates_presence_of :status, :reason

    private

    def adopt_status_and_reason
      self.status = workspace.project_status
      self.reason = workspace.project_status_reason
    end
  end
end