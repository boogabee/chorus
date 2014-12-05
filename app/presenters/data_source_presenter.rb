class DataSourcePresenter < Presenter
  def to_hash
    hash = {
        :id => model.id,
        :name => model.name,
        :entity_type => model.entity_type_name,
        :is_deleted => model.deleted?,
        :shared => model.shared,
        :owner_id => model.owner_id,
        :version => model.version,
        :is_hawq => model.is_hawq
    }
    unless succinct?
      hash.merge!({
          :host => model.host,
          :port => model.port,
          :ssl => model.ssl,
          :online => model.state == "online",
          :db_name => model.db_name,
          :description => model.description,
          :schema_blacklist => model.connect_as_owner.schema_blacklist
      }.merge(owner_hash).
      merge(tags_hash))
    end
    hash
  end

  def complete_json?
    !rendering_activities? && !succinct?
  end

  def forbidden_hash
    {
      :id => model.id,
      :entity_type => model.entity_type_name,
      :shared => model.shared,
      :owner_id => model.owner_id,
      :name => model.name
    }
  end

  private

  def tags_hash
    rendering_activities? ? {} : {:tags => present(model.tags)}
  end

  def owner_hash
    if rendering_activities?
      {}
    else
      {:owner => present(model.owner)}
    end
  end
end
