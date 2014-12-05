module Events
  class NoteOnWorkspaceDataset < Note
    has_targets :dataset, :workspace
    has_activities :actor, :dataset, :workspace

    validate :actor_is_member_of_workspace, :on => :create

    include_shared_search_fields(:dataset)
    include_shared_search_fields(:workspace)

    private

    def has_workspace?
      true
    end

    def actor_is_member_of_workspace
      errors.add(:workspace, :not_a_member) unless workspace.visible_to?(actor)
    end
  end
end