class ChorusViewPresenter < DatasetPresenter

  def to_hash
    options[:workspace] = model.workspace
    super.merge({
        :object_type => subtype,
        :query => model.query,
        :is_deleted => !model.deleted_at.nil?
    })
  end

  def has_tableau_workbooks?
    true
  end

  def subtype
    "CHORUS_VIEW"
  end
end
