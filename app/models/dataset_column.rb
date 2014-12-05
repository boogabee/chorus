class DatasetColumn
  attr_accessor :data_type, :description, :ordinal_position, :statistics, :name, :statistics

  def self.columns_for(account, dataset)
    column_class = dataset.column_type.constantize
    columns = dataset.connect_with(account).column_info(dataset.name, dataset.query_setup_sql)

    columns.map.with_index do |raw_row_data, i|
      column = column_class.new({
        :name => raw_row_data[:attname],
        :data_type => raw_row_data[:format_type],
        :description => raw_row_data[:description],
        :ordinal_position => i + 1
      })
      column.add_statistics!(raw_row_data)
      column
    end
  end

  def initialize(attributes={})
    @name = attributes[:name]
    @data_type = attributes[:data_type]
    @description = attributes[:description]
    @ordinal_position = attributes[:ordinal_position]
  end

  def add_statistics!(*)
  end

  def entity_type_name
    'database_column'
  end

  def match?(source_column)
    name.downcase == source_column.name.downcase && gpdb_data_type == source_column.gpdb_data_type
  end
end
