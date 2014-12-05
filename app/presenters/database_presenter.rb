class DatabasePresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :name => model.name,
        :data_source => present(model.data_source, options),
        :entity_type => model.entity_type_name
    }
  end

  def complete_json?
    true
  end
end
