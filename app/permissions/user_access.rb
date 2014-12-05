class UserAccess < AdminFullAccess
  def update?(user)
    user == current_user
  end

  def show?(user)
    true
  end
end
