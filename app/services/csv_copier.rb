class CsvCopier < TableCopier
  def source_dataset
    raise "no source dataset for CsvCopier, should be csv_file"
  end

  def csv_file
    source
  end

  def validate!
    unless csv_file.ready_to_import?
      raise 'CSV file cannot be imported'
    end
  end

  def load_table_definition
    csv_file.escaped_column_names.zip(csv_file.types).map{|a,b| "#{a} #{b}"}.join(", ")
  end

  def primary_key_clause
    ''
  end

  def distribution_key_clause
    TableCopier::DISTRIBUTED_RANDOMLY
  end

  def run
    destination_connection.copy_csv(
        java.io.FileReader.new(csv_file.contents.path),
        destination_table_name,
        csv_file.column_names,
        csv_file.delimiter,
        csv_file.has_header
    )
  rescue StandardError => e
    raise ImportFailed, e.message
  ensure
    csv_file.destroy
  end
end