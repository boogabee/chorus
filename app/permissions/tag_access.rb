class TagAccess < AdminFullAccess
  def destroy?(tag)
    current_user.admin?
  end
end
