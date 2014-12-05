class MyWorkspacesSearch < Search
  def models_to_search
    super & [Workspace, Workfile, Dataset]
  end

  def build_search
    super.build do
      with :workspace_id, current_user.memberships.map(&:workspace_id).sort
    end
  end
end
