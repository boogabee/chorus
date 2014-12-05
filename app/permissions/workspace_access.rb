class WorkspaceAccess < AdminFullAccess
  def self.members_for(user, workspace)
    if user.admin?
      workspace.members
    else
      workspace.members_accessible_to(user)
    end
  end

  def show?(workspace)
    workspace.visible_to?(current_user)
  end

  def destroy?(workspace)
    owner?(workspace)
  end

  alias_method :create_note_on?, :show?

  def can_edit_sub_objects?(workspace)
    !workspace.archived? && workspace.member?(current_user)
  end

  def update?(workspace)
    return false unless workspace.member?(current_user)
    if workspace.sandbox_id_changed? && workspace.sandbox_id
      return false unless workspace.owner == current_user && context.can?(:show_contents, workspace.sandbox.data_source)
    end

    effective_owner_id = workspace.owner_id_changed? ? workspace.owner_id_was : workspace.owner_id
    effective_owner_id == current_user.id || (workspace.changed - ['name', 'summary']).empty?
  end
end
