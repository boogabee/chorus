class JobResultPresenter < Presenter
  def to_hash
    hash =[:succeeded, :started_at, :finished_at, :id].inject({}) do |hash, key|
      hash[key] = model.send(key)
      hash
    end

    hash.merge!(task_results)

    hash
  end

  def task_results
    {:job_task_results => model.job_task_results.map { |result| present(result) }}
  end
end