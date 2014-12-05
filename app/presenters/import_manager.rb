class ImportManager < DelegateClass(Import)
  def started?
    started_at.present?
  end

  def procpid_sql(type)
    matcher = "%pipe%_#{handle}" + (type == :writer ? "_w" : "_r")

    <<-SQL
      SELECT procpid
      FROM pg_stat_activity
      WHERE current_query LIKE '#{matcher}%'
      AND current_query NOT LIKE '%procpid%'
    SQL
  end

  def has_source_dataset?
    respond_to?(:source_dataset)
  end

  def connection(type)
    schema = (type == :reader ? schema : source_dataset.schema)
    schema.connect_as(user)
  end

  def busy?(type)
    if using_pipe?
      connection(type).fetch(procpid_sql(type)).any?
    else
      @reader_busy ||= CancelableQuery.new(connection(:reader), handle, user).busy?
    end
  end

  def workspace_import?
    __getobj__.is_a? WorkspaceImport
  end

  def using_pipe?
    source_dataset.is_a? GpdbDataset if has_source_dataset?
  end

  def destination_dataset
    schema.datasets.find_by_name(to_table)
  end

  def named_pipe
    return "n/a" unless using_pipe?
    return unless ChorusConfig.instance.gpfdist_configured?
    dir = Pathname.new ChorusConfig.instance['gpfdist.data_dir']
    Dir.glob(dir.join "pipe*_#{created_at.to_i}_#{id}").first
  end
end
