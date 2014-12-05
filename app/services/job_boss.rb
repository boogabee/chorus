class JobBoss
  def self.run
    Job.ready_to_run.each do |job|
      begin
        if job.valid?
          job.enqueue
        else
          job.disable
          event = Events::JobDisabled.by(job.owner).add(:job => job, :workspace => job.workspace)
          Notification.create!(:event => event, :recipient => job.owner)
        end
      rescue => e
        # log to scheduler log
        p 'Handling ready_to_run jobs: ' + e.message
      end
    end

    Job.awaiting_stop.each(&:idle)
  end
end
