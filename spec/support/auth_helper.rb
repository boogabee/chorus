module AuthHelper
  def log_in(user)
    session_object = Session.new
    session_object.user = user
    session_object.save(:validate => false)
    session[:chorus_session_id] = session_object.session_id
    session_object
  end

  def log_out
    session.clear
  end
end
