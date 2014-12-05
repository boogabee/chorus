class MultiPgTableCopier < TableCopier
  include PgCopyManagerMixin
  include_package 'org.postgresql.copy'

  def run
    source_data_stream = source_connection.connect!.synchronize do |source_jdbc|
      PGCopyInputStream.new source_jdbc, copy_out_sql
    end

    copy_in(source_data_stream)
  ensure
    source_connection.disconnect
  end

  def self.cancel(import)
    source_connection = import.source.connect_as(import.user)
    source_connection.kill(import.handle)
  end

  private

  def copy_out_sql
    %(/*#{pipe_name}*/ COPY (select * from #{source_dataset.scoped_name} #{limit_clause}) TO STDOUT WITH DELIMITER ',' CSV)
  end

  def limit_clause
    sample_count ? "limit #{sample_count}" : ''
  end
end
