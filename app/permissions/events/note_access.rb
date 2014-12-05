module Events
  class NoteAccess < AdminFullAccess
    def show?(note)
      entity = note.note_target
      access = Allowy::Registry.new(context).access_control_for!(entity)
      access.show? entity
    end

    def update?(note)
      note.actor == current_user
    end

    def destroy?(note)
      note.actor == current_user || current_user.admin? || current_user_is_workspace_owner?(note)
    end

    private

    def current_user_is_workspace_owner?(note)
      note.is_a?(NoteOnWorkspace) && (current_user == note.workspace.owner)
    end
  end
end
