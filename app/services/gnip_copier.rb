class GnipCopier < TableCopier
  def run
    stream.fetch.each { |url| import_from_url(url) }
  end

  private

  def import_from_url(url)
    reader = java.io.StringReader.new(stream.to_result_in_batches([url]).contents)
    destination_connection.copy_csv(reader, destination_table_name, column_names, ',', false)
  end

  def stream
    ChorusGnip.from_stream(source.stream_url, source.username, source.password)
  end

  def primary_key_clause
    ''
  end

  def distribution_key_clause
    TableCopier::DISTRIBUTED_RANDOMLY
  end

  def load_table_definition
    column_names.zip(column_types).map{|name, type| "#{name} #{type}"}.join(", ")
  end

  def column_types
    ChorusGnip.column_types
  end

  def column_names
    ChorusGnip.column_names
  end
end