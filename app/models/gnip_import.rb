class GnipImport < Import
  unscoped_belongs_to :workspace
  attr_accessible :workspace, :source

  def self.presenter_class
    ImportPresenter
  end

  def schema
    workspace.sandbox
  end

  def create_import_event
    destination_table = schema.datasets.tables.find_by_name(to_table)
    created_event_class.by(user).add(
        :workspace => workspace,
        :dataset => destination_table,
        :destination_table => to_table,
        :gnip_data_source => source,
        :reference_id => id,
        :reference_type => 'Import'
    )
  end

  def created_event_class
    Events::GnipStreamImportCreated
  end

  def create_passed_event_and_notification
    event = Events::GnipStreamImportSuccess.by(user).add(
        :workspace => workspace,
        :dataset => destination_dataset,
        :gnip_data_source => source
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_failed_event_and_notification(error_message)
    event = Events::GnipStreamImportFailed.by(user).add(
        :workspace => workspace,
        :destination_table => to_table,
        :gnip_data_source => source,
        :error_message => error_message
    )
    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def copier_class
    GnipCopier
  end

  def validate_source!; end
end