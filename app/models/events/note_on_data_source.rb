module Events
  class NoteOnDataSource < Note
    has_targets :data_source
    has_activities :actor, :data_source, :global
  end
end