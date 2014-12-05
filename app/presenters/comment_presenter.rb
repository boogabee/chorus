class CommentPresenter < Presenter

  def to_hash
    {
        :id => model.id,
        :author => present(model.author, :succinct => true),
        :body => sanitize(model.body),
        :action => 'SUB_COMMENT',
        :timestamp => model.created_at,
        :entity_type => model.entity_type_name
    }
  end

  def complete_json?
    true
  end
end