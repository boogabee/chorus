require 'active_model'

class ExternalTable
  include ActiveModel::Validations
  include ChorusApiValidationFormat

  def self.build(options)
    new(options)
  end

  attr_accessor :column_names, :column_types, :name, :entry_or_dataset,
                :delimiter, :file_pattern

  validates_presence_of :column_names, :column_types, :name, :entry_or_dataset

  validate :delimiter_not_blank

  def initialize(options = {})
    @connection = options[:connection]
    @sandbox_data_source = options[:sandbox_data_source]
    @column_names = options[:column_names]
    @column_types = options[:column_types]
    @name = options[:name]
    @entry_or_dataset = options[:entry_or_dataset]
    @file_pattern = options[:file_pattern]
    @delimiter = options[:delimiter]
  end

  def save
    return false unless valid?
    @connection.create_external_table(
      :table_name => name,
      :columns => map_columns,
      :location_url => location_url,
      :delimiter => delimiter
    )
    true
  rescue PostgresLikeConnection::DatabaseError => e
    errors.add(:name, :TAKEN)
    false
  end

  private

  def file_pattern_string
    file_pattern ? "/#{file_pattern}" : ""
  end

  def map_columns
    (0...column_names.length).map { |i| "#{column_names[i]} #{column_types[i]}" }.join(", ")
  end

  def delimiter_not_blank
    if delimiter.nil? || delimiter.length != 1
      errors.add(:delimiter, :EMPTY)
    end
  end

  def location_url
    ext_source = entry_or_dataset.hdfs_data_source

    url = if @sandbox_data_source.is_hawq?
      "pxf://#{ext_source.host}:50070"
    else
      "gphdfs://#{ext_source.host}:#{ext_source.port}"
    end

    url += "#{entry_or_dataset.path}#{file_pattern_string}"
    url += '?Fragmenter=HdfsDataFragmenter&Accessor=TextFileAccessor&Resolver=TextResolver' if @sandbox_data_source.is_hawq?
    url
  end
end
