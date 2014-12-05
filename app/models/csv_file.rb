class CsvFile < ActiveRecord::Base
  include StaleUpload

  attr_accessible :contents, :column_names, :types, :delimiter, :to_table, :has_header, :new_table, :truncate

  serialize :column_names
  serialize :types

  belongs_to :workspace
  belongs_to :user
  belongs_to :import

  has_attached_file :contents, :path => ":rails_root/system/:class/:id/:basename.:extension"

  validates :contents, :attachment_presence => true
  validates_attachment_size :contents,
    :less_than => ChorusConfig.instance['file_sizes_mb']['csv_imports'].megabytes,
    :message => :file_size_exceeded,
    :if => :user_uploaded

  validates :user, :presence => true
  validates :workspace, :presence => true

  def escaped_column_names
    column_names.map { |column_name| %Q|"#{column_name}"| }
  end

  def table_already_exists(table_name)
    schema = workspace.sandbox
    schema.connect_as(user).table_exists?(table_name)
  end

  def ready_to_import?
    to_table.present? && column_names.present? && types.present? && has_header != nil &&
    delimiter != nil && delimiter.length > 0 && valid?
  end

  def name
    nil
  end
end
