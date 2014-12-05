class NotificationAccess < DefaultAccess
  def destroy?(notification)
    notification.recipient == current_user
  end
end