module Events
  class NoteOnWorkfile < Note
    has_targets :workfile
    has_activities :actor, :workfile, :workspace

    before_validation :set_workspace, :on => :create

    include_shared_search_fields(:workspace)

    private

    def has_workspace?
      true
    end

    def set_workspace
      self.workspace = workfile.workspace
    end
  end
end