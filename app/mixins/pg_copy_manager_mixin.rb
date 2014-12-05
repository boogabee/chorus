module PgCopyManagerMixin

  private

  def copy_in(input_stream)
    destination_connection.with_jdbc_connection do |destination_jdbc|
      destination_jdbc.copy_api.copy_in(copy_in_sql, input_stream)
    end
  end

  def copy_in_sql
    %(COPY #{destination_table_fullname} (#{quoted_source_columns}) FROM STDIN WITH DELIMITER ',' CSV)
  end

  def quoted_source_columns
    quote_and_join source_columns.map(&:name)
  end
end
