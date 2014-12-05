class WorkfileAccess < AdminFullAccess
  def show?(workfile)
    WorkspaceAccess.new(context).can? :show, workfile.workspace
  end

  def update?(workfile)
    WorkspaceAccess.new(context).can? :update, workfile.workspace
  end
end