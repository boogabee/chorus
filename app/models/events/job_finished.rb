module Events
  class JobFinished < Base
    has_targets :job, :workspace, :job_result
    has_activities :actor, :job, :workspace

    after_create :notify_workspace_members, :if => :should_notify?

    def notify_workspace_members
      selected_recipients.each do |user|
        Notification.create!(:recipient_id => user.id, :event_id => self.id)
        Mailer.notify(user, self) if user.subscribed_to_emails?
      end
    end

    def should_notify?
      notify_option != 'nobody'
    end

    def selected_recipients
      if notify_option == 'everybody'
        workspace.members
      elsif notify_option == 'selected'
        user_selected_recipients
      else
        []
      end
    end
  end
end