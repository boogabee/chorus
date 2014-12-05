class ImportSourceDataTask < JobTask
  validate :destination_name_is_unique
  validate :sandbox_exists

  belongs_to :payload, :class_name => 'ImportTemplate', :autosave => true
  belongs_to :current_import, :class_name => 'Import', :foreign_key => :killable_id

  def attach_payload(params)
    self.build_payload(params)
  end

  def perform
    result = ImportSourceDataTaskResult.new(:started_at => Time.current, :name => derived_name)
    raise StandardError.new('Canceled by User') if canceled?

    import_data

    result.finish :status => JobTaskResult::SUCCESS
  rescue StandardError => e
    result.finish :status => JobTaskResult::FAILURE, :message => e.message
  ensure
    idle!
  end

  def import_data
    import = payload.create_import
    self.update_attribute(:killable_id, import.id)
    ImportExecutor.run import.id
    payload.set_destination_id! if payload.new_table_import?
  end

  def update_attributes(params)
    payload.update_attributes(params)
    super
  end

  def kill
    current_import.mark_as_canceled!('Canceled by User') if current_import
    update_attribute(:status, JobTask::CANCELED)
  end

  def valid_payload?
    super && payload.source.present?
  end

  private

  def build_task_name
    "Import from #{payload.source.name}"
  end

  def canceled?
    reload.status == JobTask::CANCELED
  end

  def destination_name_is_unique
    if payload.new_table_import? && destination_already_exists?
      errors.add(:base, :table_exists, {:table_name => payload.destination_name})
    end
  end

  def destination_already_exists?
    workspace.sandbox && workspace.sandbox.datasets.find_by_name(payload.destination_name)
  end

  def sandbox_exists
    errors.add(:base, :EMPTY_SANDBOX) unless workspace.sandbox.present?
  end
end
