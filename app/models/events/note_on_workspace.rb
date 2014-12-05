module Events
  class NoteOnWorkspace < Note
    has_targets :workspace
    has_activities :actor, :workspace

    include_shared_search_fields(:workspace)

    def note_target=(model)
      self.workspace = model
    end

    def note_target
      self.workspace
    end

    private

    def has_workspace?
      true
    end
  end
end
