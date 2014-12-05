class TagPresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :name => model.name,
        :count => model.taggings_count,
        :entity_type => 'tag'
    }
  end
end