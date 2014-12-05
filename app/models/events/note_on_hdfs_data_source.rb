module Events
  class NoteOnHdfsDataSource < Note
    has_targets :hdfs_data_source
    has_activities :actor, :hdfs_data_source, :global
  end
end