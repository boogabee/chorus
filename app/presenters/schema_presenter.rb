class SchemaPresenter < Presenter
  def to_hash
    hash = {
        :id => model.id,
        :name => model.name,
        :dataset_count => model.active_tables_and_views_count,
        :refreshed_at => model.refreshed_at,
        :entity_type => model.entity_type_name,
        :is_deleted => model.deleted?
    }
    unless rendering_activities?
      hash.merge!({
        :data_source => present(model.data_source, options)
      })
    end
    hash
  end
end
