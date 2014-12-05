module CurrentUserHelpers
  def set_current_user(user)
    Thread.current[:user] = user
  end

  def with_current_user(user)
    Thread.current[:user] = user
    yield
  ensure
    Thread.current[:user] = nil
  end
end