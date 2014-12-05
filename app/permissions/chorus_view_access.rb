class ChorusViewAccess < AdminFullAccess
  def show?(chorus_view)
    WorkspaceAccess.new(context).can? :show, chorus_view.workspace
  end
end
