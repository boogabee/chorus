class GpdbSchemaPresenter < Presenter
  def to_hash
    hash = {
        :id => model.id,
        :name => model.name,
        :dataset_count => model.active_tables_and_views_count,
        :refreshed_at => model.refreshed_at,
        :entity_type => model.entity_type_name,
        :is_deleted => model.deleted?,
        :stale => model.stale?
    }
    unless succinct?
      hash.merge!({
        :has_credentials => model.accessible_to(current_user)
      })
    end
    unless rendering_activities?
      hash.merge!({
          :database => present(model.database, options),
      })
    end
    hash
  end

  def complete_json?
    true
  end
end
