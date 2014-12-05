require_relative 'gpdb_column_statistics'

class GpdbDatasetColumn < DatasetColumn
  def add_statistics!(raw_row_data)
    params = []
    params << raw_row_data[:null_frac]
    params << raw_row_data[:n_distinct]
    params << raw_row_data[:most_common_vals]
    params << raw_row_data[:most_common_freqs]
    params << raw_row_data[:histogram_bounds]
    params << raw_row_data[:reltuples]
    params << number_or_time?
    self.statistics = GpdbColumnStatistics.new(*params)
  end

  def simplified_type
    @simplified_type ||= ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(name, nil, data_type, nil).type
  end

  def number_or_time?
    [:decimal, :integer, :float, :date, :time, :datetime].include? simplified_type
  end

  def gpdb_data_type
    data_type
  end
end
