class JobPresenter < Presenter

  def to_hash
    job_hash = {
      :id => model.id,
      :workspace => present(model.workspace, options.merge(:succinct => options[:succinct] || options[:list_view])),
      :name => model.name,
      :next_run => in_time_zone(:next_run),
      :end_run => model.end_run,
      :time_zone => model.time_zone,
      :last_run => in_time_zone(:last_run),
      :interval_unit => model.interval_unit,
      :interval_value => model.interval_value,
      :status => model.status,
      :enabled => model.enabled,
      :last_run_failed => model.job_results.present? && !model.job_results.last.succeeded,
      :success_notify => model.success_notify,
      :failure_notify => model.failure_notify,
      :is_deleted => model.deleted?
    }
    job_hash.merge!(recipients)

    unless options[:list_view] || options[:succinct]
      job_hash.merge!(tasks)
      job_hash[:owner] = present model.owner
    end
    job_hash
  end

  def tasks
    { :tasks => present(model.job_tasks) }
  end

  private

  def recipients
    {
        :success_recipients => model.success_recipients.map { |user| user.id },
        :failure_recipients => model.failure_recipients.map { |user| user.id }
    }
  end

  def in_time_zone(key)
    if model.send(key)
      model.send(key).in_time_zone(ActiveSupport::TimeZone[model.time_zone])
    end
  end
end
