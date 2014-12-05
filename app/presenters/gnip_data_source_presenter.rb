class GnipDataSourcePresenter < Presenter
  def to_hash
    hash = {
        :id => model.id,
        :name => model.name,
        :entity_type => model.entity_type_name,
        :is_deleted => model.deleted?
    }
    unless succinct?
      hash.merge!({
          :stream_url => model.stream_url,
          :description => model.description,
          :username => model.username,
          :state => "online"
      }.merge(owner_hash).
      merge(tags_hash))
    end
    hash
  end

  def complete_json?
    !rendering_activities? && !succinct?
  end

  private

  def tags_hash
    rendering_activities? ? {} : {:tags => present(model.tags)}
  end

  def owner_hash
    if rendering_activities?
      {}
    else
      {:owner => model.owner}
    end
  end
end
