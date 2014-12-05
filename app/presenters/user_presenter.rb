class UserPresenter < Presenter

  def to_hash
    results = {
        :id => model.id,
        :username => model.username,
        :first_name => model.first_name,
        :last_name => model.last_name,
        :image => present(model.image),
        :entity_type => model.entity_type_name,
        :is_deleted => model.deleted?
    }
    unless rendering_activities? || succinct?
      results.merge!(
          :email => model.email,
          :title => model.title,
          :dept => model.dept,
          :notes => model.notes,
          :admin => model.admin?,
          :developer => model.developer?,
          :subscribed_to_emails => model.subscribed_to_emails?,
          :tags => present(model.tags)
      )
    end
    results
  end

  def complete_json?
    !rendering_activities? && !succinct?
  end
end
