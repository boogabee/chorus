class DatasetColumnPresenter < Presenter
  def to_hash
    {
      :name => model.name,
      :data_type => model.data_type.downcase,
      :type_category => type_category,
      :description => model.description,
      :statistics => statistics,
      :entity_type => model.entity_type_name
    }
  end

  def type_category
    raise 'Subclasses must define their own conversion function'
  end

  def statistics
    return { } unless model.statistics.present?
    present(model.statistics)
  end

  def complete_json?
    true
  end
end