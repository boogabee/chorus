class WorkspaceImport < Import
  unscoped_belongs_to :workspace
  validates :workspace, :presence => true
  validate :workspace_is_not_archived
  alias_attribute :source_dataset, :source

  def update_status(status, message=nil)
    super(status, message)
    associate_destination_dataset
  end

  def associate_destination_dataset
    if (destination_dataset && !workspace.has_dataset?(destination_dataset))
      workspace.associate_datasets(user, [destination_dataset])
    end
  end

  def schema
    workspace.sandbox
  end

  def create_import_event
    destination_table = schema.datasets.tables.find_by_name(to_table)
    created_event_class.by(user).add(
      :workspace => workspace,
      :source_dataset => source,
      :dataset => destination_table,
      :destination_table => to_table,
      :reference_id => id,
      :reference_type => 'Import'
    )
  end

  def created_event_class
    Events::WorkspaceImportCreated
  end

  def success_event_class
    Events::WorkspaceImportSuccess
  end

  def failed_event_class
    Events::WorkspaceImportFailed
  end

  def copier_class
    if source.is_a?(OracleDataset)
      OracleTableCopier
    elsif source.database == schema.database
      TableCopier
    elsif source.is_a?(PgDataset) || schema.is_a?(PgSchema)
      MultiPgTableCopier
    else
      GpfdistTableCopier
    end
  end

  def self.presenter_class
    ImportPresenter
  end

  def create_passed_event_and_notification
    event = success_event_class.by(user).add(
      :workspace => workspace,
      :dataset => destination_dataset,
      :source_dataset => source
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_failed_event_and_notification(error_message)
    event = failed_event_class.by(user).add(
      :workspace => workspace,
      :destination_table => to_table,
      :error_message => error_message,
      :source_dataset => source,
      :dataset => workspace.sandbox.datasets.find_by_name(to_table)
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def workspace_with_deleted
    workspace_without_deleted || Workspace.unscoped { reload.workspace_without_deleted }
  end

  alias_method_chain :workspace, :deleted
end
