class CsvImport < Import
  unscoped_belongs_to :workspace
  has_one :csv_file, :foreign_key => :import_id
  validates :workspace, :presence => true
  validate :workspace_is_not_archived
  validate :unique_column_names
  attr_accessible :workspace_id, :csv_file
  before_validation :set_file_name
  after_create :enqueue_import

  def schema
    workspace.sandbox
  end

  def create_import_event
    destination_table = schema.datasets.tables.find_by_name(to_table)
    created_event_class.by(user).add(
        :workspace => workspace,
        :dataset => destination_table,
        :file_name => file_name,
        :import_type => 'file',
        :destination_table => to_table,
        :reference_id => id,
        :reference_type => 'Import'
    )
  end

  def created_event_class
    Events::FileImportCreated
  end

  def copier_class
    CsvCopier
  end

  def self.presenter_class
    ImportPresenter
  end

  def create_passed_event_and_notification
    event = Events::FileImportSuccess.by(user).add(
        :workspace => workspace,
        :dataset => destination_dataset,
        :file_name => file_name,
        :import_type => 'file'
    )

    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def create_failed_event_and_notification(message)
    event = Events::FileImportFailed.by(user).add(
        :workspace => workspace,
        :file_name => file_name,
        :import_type => 'file',
        :destination_table => to_table,
        :error_message => message,
        :dataset => destination_dataset
    )

    Notification.create!(:recipient_id => user.id, :event_id => event.id)
  end

  def source
    csv_file
  end

  def validate_source!; end

  private

  def unique_column_names
    duplicates = csv_file.column_names.inject(Hash.new(0)) do |memo, column|
      memo[column] += 1
      memo
    end.select do |column_name, count|
      count > 1
    end.keys.uniq

    if duplicates.size > 0
      errors.add(:column_names, :duplicates, :dupes => duplicates.join(", "))
    end
  end

  def set_file_name
    self.file_name = csv_file.contents_file_name
  end
end