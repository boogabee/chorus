class JobAccess < AdminFullAccess

  def show?(job)
    job.workspace.visible_to?(current_user)
  end

  def update_owner?(job)
    current_user == job.owner || current_user == job.workspace.owner
  end
end
