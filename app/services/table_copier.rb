class TableCopier
  class ImportFailed < StandardError; end

  DISTRIBUTED_RANDOMLY = 'DISTRIBUTED RANDOMLY'

  def initialize(attributes)
    @attributes = attributes.with_indifferent_access
  end

  def self.cancel(import)
    CancelableQuery.new(nil, import.handle, import.user).cancel
  end

  def start
    validate!
    initialize_destination_table
    run
  rescue Exception => e
    destination_connection.drop_table(destination_table_name) if table_created?
    wrapped = ImportFailed.new(e.message)
    wrapped.set_backtrace e.backtrace
    raise wrapped
  end

  def validate!
  end

  def source_connection
    @source_connection ||= source_dataset.connect_as(user)
  end

  def destination_connection
    @destination_connection ||= destination_schema.connect_as(user)
  end

  def initialize_destination_table
    if !destination_connection.table_exists?(destination_table_name)
      destination_connection.create_table(destination_table_name, table_definition_with_keys, distribution_key_clause)
      @table_created = true
    elsif truncate
      destination_connection.truncate_table(destination_table_name)
    end
  end

  def run
    source_connection.copy_table_data(destination_table_fullname, source_dataset.name, source_dataset.query_setup_sql, {:limit => sample_count, :check_id => pipe_name, :user => user})
  rescue StandardError => e
    raise ImportFailed, e.message
  end

  def method_missing(name, *args, &block)
    if @attributes.key?(name)
      @attributes[name]
    else
      super
    end
  end

  def source_dataset
    source
  end

  private

  def distribution_key_clause
    return DISTRIBUTED_RANDOMLY if chorus_view?
    rows = distribution_key_columns
    rows.empty? ? DISTRIBUTED_RANDOMLY : "DISTRIBUTED BY(#{quote_and_join(rows)})"
  end

  def primary_key_clause
    if chorus_view? || is_hawq?
      primary_key_rows = []
    else
      primary_key_rows = primary_key_columns
    end
    primary_key_rows.empty? ? '' : ", PRIMARY KEY(#{quote_and_join(primary_key_rows)})"
  end

  def primary_key_columns
    @primary_key_columns ||= source_connection.primary_key_columns(source_dataset.name)
  end

  def distribution_key_columns
    @distribution_key_columns ||= source_connection.distribution_key_columns(source_dataset.name)
  end

  def load_table_definition
    source_columns.map { |column| %("#{column.name}" #{convert_column_type(column.data_type)}) }.join(', ')
  end

  def source_columns
    @source_columns ||= DatasetColumn.columns_for(source_account, source_dataset)
  end

  def source_account
    source_dataset.data_source.account_for_user!(user)
  end

  def table_definition
    @table_definition ||= load_table_definition
  end

  def table_definition_with_keys
    table_definition + primary_key_clause
  end

  def quote_and_join(collection)
    collection.map { |element| %("#{element}") }.join(', ')
  end

  def convert_column_type(type)
    type
  end

  def table_created?
    @table_created
  end

  def chorus_view?
    source_dataset.is_a?(ChorusView)
  end

  def is_hawq?
    destination_connection.is_hawq?
  end

  def destination_table_fullname
    %("#{destination_schema.name}"."#{destination_table_name}")
  end
end
