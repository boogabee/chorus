class GpdbColumnStatisticsPresenter < Presenter

  def to_hash
    {
      :distinct_value => model.number_distinct,
      :common_values => model.common_values,
      :null_fraction => model.null_fraction,
      :min => model.min,
      :max => model.max,
      :entity_type => model.entity_type_name
    }
  end

  def complete_json?
    true
  end
end