class NotificationPresenter < Presenter
  def to_hash
    event_presenter = EventPresenter.new(model.event, @view_context, options)
    {
        :id => model.id,
        :recipient => present(model.recipient, options),
        :event => event_presenter.simple_hash,
        :comment => present(model.comment, options),
        :unread => !(model.read),
        :timestamp => model.created_at
    }
  end

  def complete_json?
    true
  end
end