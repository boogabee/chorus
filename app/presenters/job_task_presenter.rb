class JobTaskPresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :job => present(model.job, succinct: true),
      :action => model.action,
      :index => model.index,
      :name => model.derived_name,
      :is_deleted => model.deleted?,
      :is_valid => model.valid_payload?
    }
  end
end
