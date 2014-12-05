class JobTaskResultPresenter < Presenter
  def to_hash
    [:status, :started_at, :finished_at, :name, :message, :id, :payload_result_id, :payload_id].inject({}) do |hash, key|
      hash[key] = model.send(key)
      hash
    end
  end
end