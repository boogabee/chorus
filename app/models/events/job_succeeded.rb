module Events
  class JobSucceeded < JobFinished
    def self.succeeded
      true
    end

    def header
      "Job #{job.name} succeeded in workspace #{workspace.name}."
    end

    def notify_option
      job.success_notify
    end

    def user_selected_recipients
      job.success_recipients
    end
  end
end