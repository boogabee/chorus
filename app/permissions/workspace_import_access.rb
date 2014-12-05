class WorkspaceImportAccess < AdminFullAccess
  def update?(import)
    current_user == import.user
  end
end
