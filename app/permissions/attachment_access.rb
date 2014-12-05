class AttachmentAccess < DefaultAccess
  def create?(klass, event)
    current_user.id == event.actor.id
  end
end
