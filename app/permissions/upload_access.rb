class UploadAccess < AdminFullAccess
  def use?(upload)
    upload.user == current_user
  end
end
