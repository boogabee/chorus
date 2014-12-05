class RunSqlWorkfileTask < JobTask

  belongs_to :payload, :class_name => 'ChorusWorkfile'

  def perform
    result = ImportSourceDataTaskResult.new(:started_at => Time.current, :name => derived_name)

    query = CancelableQuery.new(account, 'exe_id', job.owner)
    query.execute(sql, :limit => 0, :include_public_schema_in_search_path => true)

    result.finish :status => JobTaskResult::SUCCESS
  rescue StandardError => e
    result.finish :status => JobTaskResult::FAILURE, :message => e.message
  ensure
    idle!
  end

  def attach_payload(params)
    self.payload = workspace.workfiles.with_file_type('sql').find params[:workfile_id]
  end

  def update_attributes(params)
    attach_payload(params) if params[:workfile_id]
    super
  end

  private

  def build_task_name
    "Run #{payload.file_name}"
  end

  def account
    payload.execution_schema.connect_as(job.owner)
  end

  def sql
    payload.latest_workfile_version.get_content
  end
end
